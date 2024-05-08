target = a.out

OBJS = main.o udp.o ip.o

INC = -I. -Iudp -Iip

$(target): $(OBJS)
	g++ -o $(target) $(OBJS)

main.o: main.cpp
	g++ -c $< -o $@ $(INC)

udp.o: udp/udp.cpp udp/udp.h
	g++ -c $< -o $@ $(INC)

ip.o: ip/ip.cpp ip/ip.h
	g++ -c $< -o $@ $(INC)
