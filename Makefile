CC	=	ghc

SRC	=	main.hs

NAME	=	wolfram

all	:	$(NAME)

$(NAME)	:
		$(CC) -o $(NAME) $(SRC)

clean   :
		$(RM) $(SRC:.hs=.o) $(SRC:.hs=.hi)

fclean	: clean
		$(RM) $(NAME)

re	: fclean
	$(CC) -o $(NAME) $(SRC)

