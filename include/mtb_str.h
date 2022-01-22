#ifndef _MTB_STR_H_
#define _MTB_STR_H_

char *mtbs_new(char *str);
char *mtbs_new_size(char *str, int size);
char *mtbs_join(int n, char *_self, ...);
void mtbs_concat(int n, char **_self, ...);
char *mtbs_substr(char *_self, int begin, int end);
char **mtbs_split(char *_self, int *nstrings, char *delims);
void mtbs_free_split(char **s, int n);

#endif
