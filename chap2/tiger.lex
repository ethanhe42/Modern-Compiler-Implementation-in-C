%{
#include <string.h>
#include "util.h"
#include "tokens.h"
#include "errormsg.h"

int charPos=1;

// comments depth and strings defines
const int INITIAL_BUF_LEN = 32;
char *str_buf;
unsigned int str_buf_cap;
int commentNesting = 0;

void init_str_buf(void){
    str_buf = checked_malloc(INITIAL_BUF_LEN);
    // 0 stands for end in a char array
    str_buf[0] = 0;
    str_buf_cap = INITIAL_BUF_LEN;
}
static void append_char2str_buf(char ch){
    size_t new_length = strlen(str_buf) + 1;
    if (new_length == str_buf_cap){
        char *temp;
        str_buf_cap *= 2;
        temp = checked_malloc(str_buf_cap);
        memcpy(temp, str_buf, new_length);
        free(str_buf);
        str_buf = temp;
    }
    str_buf[new_length - 1] = ch;
    str_buf[new_length] = 0;
}

int yywrap(void)
{
 charPos=1;
 return 1;
}

void adjust(void)
{
 EM_tokPos=charPos;
 charPos+=yyleng;
}

%}
/* lex definitions */

digits [0-9]+

%option nounput
%option noinput

%x COMMENT STRING_STATE

%%

[\r\t] {adjust(); continue;}

  /* reserved words */
array {adjust(); return ARRAY;}
if   {adjust(); return IF;}
then {adjust(); return THEN;}
else {adjust(); return ELSE;}
while {adjust(); return WHILE;}
for  	 {adjust(); return FOR;}
to  {adjust(); return TO;}
do  {adjust(); return DO;}
let  {adjust(); return LET;}
in   {adjust(); return IN;}
end   {adjust(); return END;}
of   {adjust(); return OF;}
break   {adjust(); return BREAK;}
nil   {adjust(); return NIL;}
function   {adjust(); return FUNCTION;}
var   {adjust(); return VAR;}
type   {adjust(); return TYPE;}

  /*punctuations*/
":" {adjust(); return COLON;}
";" {adjust(); return SEMICOLON;}
"(" {adjust(); return LPAREN;}
")" {adjust(); return RPAREN;}
"[" {adjust(); return LBRACK;}
"]" {adjust(); return RBRACK;}
"{" {adjust(); return LBRACE;}
"}" {adjust(); return RBRACE;}
"." {adjust(); return DOT;}
"+" {adjust(); return PLUS;}
"-" {adjust(); return MINUS;}
"*" {adjust(); return TIMES;}
"/" {adjust(); return DIVIDE;}
"=" {adjust(); return EQ;}
"<>" {adjust(); return NEQ;}
"<" {adjust(); return LT;}
"<=" {adjust(); return LE;}
">" {adjust(); return GT;}
">=" {adjust(); return GE;}
"&" {adjust(); return AND;}
"|" {adjust(); return OR;}
":=" {adjust(); return ASSIGN;}


  /* Identifiers. */
[a-zA-Z][a-zA-Z0-9]* {adjust();yylval.sval=String(yytext); return ID;}

\" {adjust(); init_str_buf(); BEGIN(STRING_STATE);}
"/*" { adjust(); commentNesting++; BEGIN(COMMENT);}
"*/" { adjust(); 
    EM_error(EM_tokPos, "close comment before open it");
    yyterminate();}


" "	 {adjust(); continue;}
\n	 {adjust(); EM_newline(); continue;}
","	 {adjust(); return COMMA;}
  /* integers */
{digits}	 {adjust(); yylval.ival=atoi(yytext); return INT;}
.	 {adjust(); EM_error(EM_tokPos,"illegal token");}

<STRING_STATE>{
    \" {
        adjust(); 
        BEGIN(INITIAL);
        yylval.sval = strdup(str_buf); 
        return STRING;}
    \\n {adjust(); append_char2str_buf('\n');}
    \\t {adjust(); append_char2str_buf('\t');}

    /*
     * The control character c, for any appropriate c, in caret notation.
     * See http://en.wikipedia.org/wiki/ASCII#ASCII_control_characters for
     * a list.
     */
    "\^"[@A-Z\[\\\]\^_?] {
                           adjust();
                           append_char2str_buf(yytext[1]-'@');
                         }
    \\[0-9]{3} {
        adjust();
        int result;
        // yytext + 1 to omit the backslash
        sscanf(yytext + 1, "%d", &result);
        if (result > 0xff) {
            EM_error(EM_tokPos, "ASCII decimal out of bounds");
            yyterminate();
        }
        append_char2str_buf(result);
    }

    "\\\"" {adjust(); append_char2str_buf('"');}
    "\\\\" {adjust(); append_char2str_buf('\\');}


    \\[ \t\n\r]+\\ {
        adjust();
        int i;
        for(i = 0; yytext[i]; i++) {
            if (yytext[i] == '\n') {
                EM_newline();
            }
        }
        continue;
    }

    <<EOF>> {
        EM_error(EM_tokPos, "STR EOF");
        yyterminate();
    }

    \\ {
        EM_error(EM_tokPos, "Error using slash");
        yyterminate();
    }
    . {
        adjust();
        char *yptr=yytext;
        append_char2str_buf(*yptr);
    }
}
<COMMENT>{
    "/*" {
        adjust();
        commentNesting++;
        continue;
    }
    "*/" {
        adjust();
        commentNesting--;
        if(commentNesting == 0){
            BEGIN(INITIAL);
        }
    }
    <<EOF>> {
        EM_error(EM_tokPos, "EOF in Comment");
        yyterminate();
    }
    . {
        adjust();
    }
            
}