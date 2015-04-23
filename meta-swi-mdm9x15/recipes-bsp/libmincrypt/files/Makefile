libmincrypt.a: rsa.o sha.o
	$(AR) $(ARFLAGS) $@ $^

rsa.o: rsa.c ../include/mincrypt/rsa.h
	$(CC) $(INCLUDES) -I./include $(CFLAGS) -c $<

sha.o: sha.c ../include/mincrypt/sha.h
	$(CC) $(INCLUDES) -I./include $(CFLAGS) -c $<

