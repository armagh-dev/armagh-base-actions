// Copyright 2018 Noragh Analytics, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied.
//
// See the License for the specific language governing permissions and
// limitations under the License.
//
//

#include <ruby.h>
#include "extconf.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <libgen.h>
#include <string.h>
#include <errno.h>
#include <regex.h>



///////////////////////////////////////////////////////////////////////////////////////
//                                                                                   //
//  NOTE: This code is *not* thread-safe: neither systems threads nor ruby threads.  //
//                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////



// C version of args to ext_json_divide -- no need to free
long     size_per_part;
char    *divide_target;
char    *filename;
VALUE    element_map;

//
// def ext_json_divide(size_per_part, divide_target, filename, element_map)
//    returns Array [header, footer] and fills in element_map
//
//    raises DivideTargetNotFoundInFirstChunkError
//        if divide_target not found within first size_per_part bytes of file
//    raises JSONParseError      if JSON parse error detected (does *not* do a full parse check)
//    raises SizeError           if footer larger than size_per_part bytes
//    raises ExtJSONDividerError for any C-specific error (fopen, regcomp, regexec, ...)
//
VALUE ext_json_divide(VALUE self, VALUE r_size_per_part, VALUE r_divide_target, VALUE r_filename, VALUE r_element_map) {
  //
  // check ruby vars & initialize C vars from ruby vars,
  // then call the workhorse by wrapping it in an rb_ensure()
  // to ensure that reset() is called to fclose() at exit,
  // whether we raise an Exception or not
  //
  //  NOTE: This code is *not* thread-safe: neither systems threads nor ruby threads.  //
  //

  VALUE ext_json_divide_workhorse(VALUE _unused);
  VALUE reset(VALUE _unused);

  Check_Type(r_size_per_part, T_FIXNUM);
  Check_Type(r_divide_target, T_STRING);
  Check_Type(r_filename,      T_STRING);
  Check_Type(r_element_map,   T_ARRAY);

  size_per_part = NUM2INT(r_size_per_part);
  divide_target = StringValueCStr(r_divide_target);
  filename      = StringValueCStr(r_filename);
  element_map   = r_element_map;

  // wrap workhorse in an ensure, so that reset gets called, whether or not we raise an Exception
  return rb_ensure(ext_json_divide_workhorse, Qnil, reset, Qnil);
}



VALUE ExtJSONDivider;

VALUE JSONDivider;
VALUE Element;
VALUE JSONParseError;
VALUE SizeError;
VALUE ExtJSONDividerError;
VALUE DivideTargetNotFoundInFirstChunkError;

void Init_ext_json_divider() {
  ExtJSONDivider = rb_define_module("ExtJSONDivider");
  rb_define_module_function(ExtJSONDivider, "ext_json_divide", ext_json_divide, 4);
}

void set_ruby_klass_vars() {
  JSONDivider         = rb_const_get(rb_cObject,  rb_intern("JSONDivider"));
  Element             = rb_const_get(JSONDivider, rb_intern("Element"));
  JSONParseError      = rb_const_get(JSONDivider, rb_intern("JSONParseError"));
  SizeError           = rb_const_get(JSONDivider, rb_intern("SizeError"));
  ExtJSONDividerError = rb_const_get(JSONDivider, rb_intern("ExtJSONDividerError"));
  DivideTargetNotFoundInFirstChunkError = rb_const_get(JSONDivider, rb_intern("DivideTargetNotFoundInFirstChunkError"));
}



// global vars
char     errbuf[BUFSIZ];        // no need to free
FILE    *fp           = NULL;   // must fclose()
char    *buf          = NULL;   // not to be free()'ed -- will grow as necessary
long     bufsiz       = 0;      // will be set to max size_per_part seen so far
long     pos_buf      = 0;
long     pos_next_buf = 0;

// to be called at the beginning and at the end of ext_json_divide()
VALUE reset(VALUE _unused) {
  void raise_c_error(const char *msg);

  if (fp)  fclose(fp);  fp = NULL;

  if (bufsiz < size_per_part) {
    if (buf)  free(buf);

    bufsiz = size_per_part;
    buf    = malloc(bufsiz);
    if (buf == NULL)  raise_c_error("malloc");
  }

  pos_buf      = 0;
  pos_next_buf = 0;
  *buf         = '\0';

  return Qnil;
}



void raise_c_error(const char *msg) {
  if (errno != 0) {
    rb_raise(ExtJSONDividerError, "%s: %s (%d)", msg, strerror(errno), errno);
  } else {
    rb_raise(ExtJSONDividerError, "%s", msg);
  }
}

void raise_c_regex_error(const char *msg, regex_t *regex, int errcode) {
  regerror(errcode, regex, errbuf, sizeof(errbuf));
  regfree(regex);
  rb_raise(ExtJSONDividerError, "%s: %s (%d)", msg, errbuf, errcode);
}

long file_pos(char *str_in_buf) {
  return pos_buf + (str_in_buf - buf);
}

char *fread_next_buf() {
  unsigned long n;

  n = fread(buf, sizeof(char), bufsiz - 1, fp);
  if (n <= 0) {
    if (feof(fp)) {
      *buf = '\0';
      return NULL;
    } else {
      raise_c_error("fread");
    }
  }
  *(buf + n) = '\0';

  pos_buf       = pos_next_buf;
  pos_next_buf += n;

  return buf;
}

char *file_strpbrk(char *s, const char *charset) {
  char *pch;

  pch = strpbrk(s, charset);
  if (pch)  return pch;

  while (fread_next_buf()) {
    pch = strpbrk(buf, charset);
    if (pch)  return pch;
  }

  return NULL;
}

char *find_end_string(char *pch) {
  long start_pos = file_pos(pch);

  while ((pch = file_strpbrk(pch+1, "\\\"")) != NULL) {
    switch (*pch) {
    case '\\':
      pch++;
      if (*pch == '\0') {
        fread_next_buf();
        pch = buf - 1;  // yes, before buf, but we do file_strpbrk(pch+1, ...)
      }
      break;
    case '"':
      return pch;
    }
  }

  rb_raise(JSONParseError, "non-terminated String starting at position %ld", start_pos);
}

char *find_end_hash_or_array(const char *type, char *pch) {
  const char *charset   = NULL;
  long        start_pos = file_pos(pch);
  int         nesting;

  if (!strcmp(type, "Hash")) {
    charset = "\"{}";
  } else if (!strcmp(type, "Array")) {
    charset = "\"[]";
  } else {
    errno = 0;
    snprintf(errbuf, sizeof(errbuf), "find_end_hash_or_array: invalid type \"%s\"", type);
    raise_c_error(errbuf);
  }

  nesting = 0;
  while ((pch = file_strpbrk(pch+1, charset)) != NULL) {
    switch (*pch) {
    case '"':
      pch = find_end_string(pch);
      break;
    case '{':
    case '[':
      nesting++;
      break;
    case '}':
    case ']':
      if ((nesting--) == 0)  return pch;
      break;
    }
  }

  rb_raise(JSONParseError, "non-terminated %s starting at position %ld", type, start_pos);
}

char *find_end_hash(char *pch) {
  return find_end_hash_or_array("Hash", pch);
}

char *find_end_array(char *pch) {
  return find_end_hash_or_array("Array", pch);
}

char *find_end_header(char *divide_target) {
  static char pattern[BUFSIZ];

  regex_t     regex[1];   // must regfree() before return
  regmatch_t  match[1];
  int         errcode;
  int         cflags = 0;

#ifdef REG_ENHANCED
  // MacOS but not Centos
  cflags = REG_ENHANCED;
#endif

  snprintf(pattern, sizeof(pattern), "[^\\\\]\"%s\"\\s*:\\s*\\[", divide_target);
  if ((errcode = regcomp(regex, pattern, cflags)) != 0) {
    raise_c_regex_error("regcomp", regex, errcode);  // this will regfree(regex)
  }

  if (*buf == '\0')  fread_next_buf();

  errcode = regexec(regex, buf, 1, match, 0);
  if (errcode == REG_NOMATCH) {
    regfree(regex);
    rb_raise(DivideTargetNotFoundInFirstChunkError, "divide_target pattern not found in first %ld bytes: %s", size_per_part, pattern);
  } else if (errcode != 0) {
    raise_c_regex_error("regexec", regex, errcode);  // this will regfree(regex)
  }

  regfree(regex);

  if (match->rm_eo > size_per_part)  rb_raise(DivideTargetNotFoundInFirstChunkError, "divide_target pattern not found in first %ld bytes: %s", size_per_part, pattern);

  return buf + match->rm_eo - 1;
}

VALUE get_footer(char *pch) {
  VALUE  r_footer = Qnil;
  long   size     = 0;
  char  *c_footer;      // must free() before return
  char  *c_footer_sav;  // to free(), if realloc() fails

  c_footer = strdup(pch);
  if (c_footer == NULL)  raise_c_error("strdup");
  if (fread_next_buf() != NULL) {
    size = strlen(c_footer) + strlen(buf);
    if (size > size_per_part)  goto FOOTER_TOO_LARGE_IF_Qnil;
    c_footer_sav = c_footer;
    c_footer     = realloc(c_footer, size + 1);
    if (c_footer == NULL) {
      free(c_footer_sav);
      raise_c_error("realloc");
    }
    strcat(c_footer, buf);

    if (fread_next_buf() != NULL) {
      size += strlen(buf);
      goto FOOTER_TOO_LARGE_IF_Qnil;
    }
  }

  r_footer = rb_str_new2(c_footer);

FOOTER_TOO_LARGE_IF_Qnil:
  free(c_footer);

  if (r_footer == Qnil)  rb_raise(SizeError, "The footer_size for %s is at least %ld, which is greater than the size_per_part of: %ld", basename(filename), size, size_per_part);

  return r_footer;
}

VALUE new_element(long pos_start, long pos_end) {
  VALUE args[] = {INT2NUM(pos_end - pos_start + 1), INT2NUM(pos_start)};

  return rb_class_new_instance(2, args, Element);
}



VALUE ext_json_divide_workhorse(VALUE _unused) {
  VALUE  header_footer = rb_ary_new();
  char  *pch;
  char   ch_sav;
  long   start_pos;
  long   pos_el_start;
  long   pos_el_end;

  set_ruby_klass_vars();
  reset(Qnil);

  fp = fopen(filename, "r");
  if (!fp) {
    snprintf(errbuf, sizeof(errbuf), "fopen(%s)", filename);
    raise_c_error(errbuf);
  }

  pch      = find_end_header(divide_target);  // raises Exception if divide_target not found
  ch_sav   = *(pch+1);
  *(pch+1) = '\0';
  rb_ary_push(header_footer, rb_str_new2(buf));
  *(pch+1) = ch_sav;

  // start of divide_target Array
  start_pos = file_pos(pch);
  while ((pch = file_strpbrk(pch+1, "\"{[]")) != NULL) {
    switch (*pch) {
    case '"':
      pch = find_end_string(pch);
            // ignore non-Hash elements
      break;
    case '{':
      pos_el_start = file_pos(pch);
      pch          = find_end_hash(pch);
      pos_el_end   = file_pos(pch);
      rb_ary_push(element_map, new_element(pos_el_start, pos_el_end));
      break;
    case '[':
      pch = find_end_array(pch);
            // ignore non-Hash elements
      break;
    case ']':
      // found end of divide_target Array
      rb_ary_push(header_footer, get_footer(pch));
      return header_footer;
    }
  }

  rb_raise(JSONParseError, "non-terminated divide_target Array starting at position %ld", start_pos);
}
