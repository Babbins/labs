extern int lab4(void);	
extern int uart_init(void);
extern int pin_block(void);
extern int gpio_setup(void);

int main()
{ 	
   pin_block();
   uart_init();
   gpio_setup();
   lab4();
}
