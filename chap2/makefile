CFLAGS = -g -Wall -Wextra

lextest: driver.o lex.yy.o errormsg.o util.o
	gcc $(CFLAGS) -o lextest driver.o lex.yy.o errormsg.o util.o

driver.o: driver.c tokens.h errormsg.h util.h
	gcc $(CFLAGS) -c driver.c

errormsg.o: errormsg.c errormsg.h util.h
	gcc $(CFLAGS) -c errormsg.c

lex.yy.o: lex.yy.c tokens.h errormsg.h util.h
	gcc $(CFLAGS) -c lex.yy.c

lex.yy.c: tiger.lex
	flex tiger.lex

util.o: util.c util.h
	gcc $(CFLAGS) -c util.c

clean: 
	rm -f a.out util.o driver.o lex.yy.o lex.yy.c errormsg.o
