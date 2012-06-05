###############################################################################
#                                                                             #
#                                                                             #
#  benchmark - Programa de benchmarking de la memoria y cache                 #
#                                                                             #
#  Disenado por:                                                              #
#       - Yendry Rojas Rodriguez  (201025588)                                 #
#       - Enmanuel Oviedo Ramírez (201041992)                                 #
#       - Alonso Vega Brenes      (201042592)                                 #
#                                                                             #
#  TEC, Santa Clara                                                           #
#  Arquitectura de Computadores (IC3101)                                      #
#  Profesor Santiago Nunez Corrales                                           #
#  _________________________________________________________________________  #
#                                                                             #
#  Uso:  ./benchmark-io n bandera                                             #
#                                                                             #
#  n:    Valor que define la cantidad de veces que seran ejecutadas las       #
#        instrucciones                                                        #
#  bandera: Indica si el algoritmo provocara cache misses o no.               #
#        -cm   : Provocar cache misses                                        #
#        -nocm : Sin provocar cache misses                                    #
#                                                                             #
#                                                                             #
###############################################################################

.section .data

	# Constantes de posicion de parametros en funciones
	.equ ARG1, 8				# Posicion del argumento 1
	.equ ARG2, 12				# Posicion del argumento 2
	.equ ARG3, 16				# Posicion del argumento 3
	.equ ARG4, 20				# Posicion del argumento 4
	.equ ARG5, 24				# Posicion del argumento 5
	.equ SYSCALL, 0x80			# Codigo de llamada al sistema

	# Manejo de archivos
	.equ READ, 3				# Leer
	.equ WRITE, 4				# Escribir
	.equ OPEN, 5				# Abrir
	.equ CLOSE, 6				# Cerrar
	.equ UNLINK, 10				# Eliminar

	# File Descriptors de Consola
	.equ STDIN, 0				# Lectura de consola
	.equ STDOUT, 1				# Escritura de consola

	# Valores de tamano de memoria
	.equ MEGABYTE, 1024 * 1024

	# Mensajes de error del programa
	ERR_PARAMETROS:	.ascii	"- La cantidad de parametros no es correcta\n\0"
	ERR_BANDERA:	.ascii	"- Error en la bandera de operacion\n\0"
	ERR_ITERACION:	.ascii	"- El valor de iteraciones no es correcto\n\0"
	# Mensaje de ayuda
	TEXTO_AYUDA:	.ascii	"- Uso del programa: \n./benchmark n flag\n"
	.ascii	"\tn = cantidad de instrucciones\n"
	.ascii	"\tflag: \t-cm : Provocar cache miss\n\t\t-nocm : Sin cache miss\n\0"
	# Texto de resultado
	TEXTO_RES1:		.ascii	"Total de iteraciones ejecutadas: \0"
	TEXTO_RES2:		.ascii	".\nAproximado de instrucciones totales: \0"
	TEXTO_RES3:		.ascii	".\n\0"
	# Espacio para almacenar numero textual en funcion printN
	number:			.ascii "\0"		# almacena el caracter a imprimir

.section .bss
	# Buffer de 10 MB: contiene las posiciones de memoria que se visitaran
	.lcomm	BUFFER, 10 * MEGABYTE

.section .text
  .global _start

	# Argumentos de entrada del programa
	.equ	ARGC, 0				# Cuenta de argumentos
	.equ	P_N_PROGRAM, 4		# Nombre del programa
	.equ	P_ITERACION, 8		# Valor de n
	.equ	P_BANDERA, 12		# Bandera de cache miss

	# Variables locales de n y bandera
	.equ 	ITERACIONES, -4		# Desplazamiento en entero
	.equ 	BANDERA, -8			# Valor de la bandera

_start:
	movl	%esp, %ebp

	# Variables locales
	subl	$8, %esp				# Espacio para las variables nuevas

	# Comprobar la cantidad de parametros recibida
	cmp		$3, ARGC(%ebp)			# Comprobar cantidad de args.
	jne		start_error_parametros	# Error si ARGC != 5

	# Revisar el valor de n
	pushl	P_ITERACION(%ebp)		# Enviar despl. como parametro
	call	string_int				# Convertir de texto a numero entero
	addl	$4, %esp				# Liberar espacio de parametro

	cmp		$0, %eax				# Si el desplazamiento es menor a cero
	jl		start_error_iteracion	# es un error
	movl	%eax, ITERACIONES(%ebp)	# Se almacena el entero

	# Revisar la bandera
	pushl	P_BANDERA(%ebp)			# Se envia la bandera como parametro
	call	funcm					# Se comprueba si es -cm, -nocm o error
	addl	$4, %esp				# Liberar espacio de parametro

	cmp		$-1, %eax				# Si el resultado es -1
	je		start_error_bandera		# Saltar al mensaje de error
	cmp		$2, %eax				# Si el resultado es mayor o igual a 2
	jge		start_error_bandera		# Saltar al mensaje de error
	movl	%eax, BANDERA(%ebp)		# Almacenar resultado localmente

	# Limpiar registros de uso general
	xorl	%eax, %eax
	xorl	%ebx, %ebx
	xorl	%ecx, %ecx
	xorl	%edx, %edx
	# Mover la cantidad de iteraciones (n) a %edi
	movl	ITERACIONES(%ebp), %edi

	# Inicio del primer ciclo
start_loop1:
	cmpl	%edi, %ebx				# Verificar si ya no debe entrar mas
	je		start_ok				# Entonces saltar al final

	incl	%ebx					# Incrementar "x" 
	xorl	%ecx, %ecx				# Limpiar "y"

	# Inicio del segundo ciclo
start_loop2:
	cmpl	%edi, %ecx				# Verificar si se debe salir del 2do ciclo
	je		start_loop1				# Volver al ciclo inicial

	incl	%ecx					# Incrementar "y"
	xorl	%edx, %edx				# Limpiar "z"

	# Inicio del tercer ciclo
start_loop3:
	cmpl	%edi, %edx				# Verificar z con respecto a n
	je		start_loop2				# Si es igual, saltar al ciclo superior
	# Respaldar los registros generales
	pushl	%eax
	pushl	%ebx
	pushl	%ecx
	pushl	%edx

	# Formula para calcular la posicion de memoria que se accesara
	# mem[buffer + (bandera  * ((z % 10) * 1 MB))]
	# De esta forma cuando se ingresa -nocm la bandera sera cero
	# y la posicion de memoria sera siempre mem[buffer]
	# Por otra parte, al utilizar -cm, se revisaran posiciones de memoria
	# separadas por 1 MB, lo que provocara cache misses
	movl	%edx, %eax			# eax = z
	movl	$10, %ebx			# ebx = 10
	xorl	%edx, %edx			# limpiar %edx
	idivl	%ebx				# edx = z % 10
	movl	%edx, %eax			# eax = edx = z % 10
	movl	$MEGABYTE, %ebx		# ebx = 1 MB
	mull	%ebx				# eax = (z % 10) * 1 MB
	movl	BANDERA(%ebp), %ecx	# ecx = bandera
	mull	%ecx				# eax = bandera * eax
	addl	$BUFFER, %eax		# BUFFER + anterior
	movl	(%eax), %ebx		# Traer de memoria

	# Devolver los valores anteriormente respaldados
	popl	%edx
	popl	%ecx
	popl	%ebx
	popl	%eax

	incl	%edx					# Incrementar "z"
	# Incrementar "a" que funciona como contador de instrucciones
	incl	%eax
	jmp		start_loop3				# Ir a siguiente iteracion

start_error_parametros:
	pushl	$ERR_PARAMETROS			# Enviar texto error de parametros
	call	printf					# Imprimir ese texto
	addl	$4, %esp				# Liberar espacio de parametro
	call	ayuda					# Mostrar texto de ayuda
	movl	$1, %ebx				# Error con la cantidad de parametros
	jmp		start_fin				# Ir al fin del programa

start_error_iteracion:
	pushl	$ERR_ITERACION			# Enviar texto error de desplazamiento
	call	printf					# Imprimir ese texto
	addl	$4, %esp				# Liberar espacio de parametro
	call	ayuda					# Mostrar texto de ayuda
	movl	$4, %ebx				# Error en el desplazamiento
	jmp		start_fin				# Ir al fin del programa

start_error_bandera:
	pushl	$ERR_BANDERA			# Enviar texto error de bandera
	call	printf					# Imprimir ese texto
	addl	$4, %esp				# Liberar espacio de parametro
	call	ayuda					# Mostrar texto de ayuda
	movl	$3, %ebx				# Error en el argumento de bandera
	jmp		start_fin				# Ir al fin del programa

start_ok:
	pushl	%eax					# Respaldar total de iteraciones
	pushl	%eax					

	# Imprimir texto de resultado inicial
	pushl	$TEXTO_RES1
	call	printf
	addl	$4, %esp

	# Mostrar total de iteraciones
	popl	%eax
	pushl	%eax
	call	printN
	addl	$4, %esp

	# Imprimir 2da parte del texto de resultado
	pushl	$TEXTO_RES2
	call	printf
	addl	$4, %esp

	popl	%eax
	imull	$11, %eax
	pushl	%eax
	call	printN
	addl	$4, %esp

	# Imprimir final del texto de resultado
	pushl	$TEXTO_RES3
	call	printf
	addl	$4, %esp

	movl	$0, %ebx				# No hay errores

	# Finalizar programa
start_fin:
	movl	$1, %eax				# Codigo de salida
	int		$SYSCALL				# Llamada a sistema

  # ___________________________________________________________________________
  # funcm ( cadena )
  # devuelve 0 si la bandera de entrada es igual a -cm,
  # 1 si la bandera de entrada es igual a -nocm
  # y -1 en cualquier otro caso

.type funcm, @function 
funcm:
	pushl 	%ebp  
	movl 	%esp, %ebp
  
	xorl 	%eax, %eax				# limpia el registro eax
	xorl 	%ebx, %ebx				# limpia el registro ebx
	xorl 	%edx, %edx				# limpia el registro edx
	xorl 	%edi, %edi				# limpia el registro edi

	movl 	ARG1(%ebp), %ebx		# carga el parametro de la funcion en ebx
	movb 	(%ebx, %edi, 1), %dl	# carga el primer caracter de la cadena
  
	cmpb 	$'-' ,%dl				# compara si la cadena es correcta
	jne 	funcm_error				# salto a indicador de error	

	incl 	%edi					# incremento de indice
	movb 	(%ebx, %edi, 1), %dl	# carga el segundo caracter de la cadena
	cmpb 	$'c' ,%dl				# compara si el caracter es = 'c'
	jne 	funcm_if_nocm
  
	incl 	%edi					# incremento de indice
	movb 	(%ebx, %edi, 1), %dl	# carga el tercer caracter de la cadena
	cmpb 	$'m' ,%dl				# compara si el caracter es = 'm'
	jne 	funcm_error
  
	incl 	%edi
	movb 	(%ebx, %edi, 1), %dl	# carga el tercer caracter de la cadena
	cmpb 	$0 ,%dl					# si existe un valor distinto al final
	jg 		funcm_error				# de la cadena, si es asi salta a error

	movl 	$1, %eax				# carga el valor de retono en eax
	jmp 	funcm_final				# salto al final de la funcion 

funcm_if_nocm:						# segunda condicion
	cmpb 	$'n' ,%dl				# compara si la bandera de entrada es -nocm
	jne 	funcm_error				# salto a indicador de error
 
	incl 	%edi					# incremento de indice
	movb 	(%ebx, %edi, 1), %dl	# carga el tercer caracter de la cadena
	cmpb 	$'o' ,%dl				# compara si el caracter es = 'o'
	jne 	funcm_error				# salto a indicador de error

	incl 	%edi					# incremento de indice
	movb 	(%ebx, %edi, 1), %dl	# carga el cuarto caracter de la cadena
	cmpb 	$'c' ,%dl				# compara si la bandera de entrada es -d
	jne 	funcm_error				# salto a indicador de error	

	incl 	%edi
	movb 	(%ebx, %edi, 1), %dl	# carga el quinto caracter de la cadena
	cmpb 	$'m' ,%dl				# compara si el caracter es = 'm'
	jne 	funcm_error				# salto a indicador de error		

	incl 	%edi
	movb 	(%ebx, %edi, 1), %dl	# carga el sexto caracter de la cadena
	cmpb 	$0 ,%dl					# compara si el caracter final es diferente al
									# esperado (\0). si es asi salta a error
	jg 		funcm_error		

	movl	$0, %eax				# carga el valor de retono en eax
	jmp		funcm_final				# salto al final de la funcion 

funcm_error:
	movl 	$-1, %eax				# carga un valor de error en eax

funcm_final:
	movl	%ebp, %esp
	popl	%ebp
	ret

  # ___________________________________________________________________________
  # printf ( cadena )
  # Imprime en consola un texto
  .type printf, @function
printf:
	pushl	%ebp  
	movl	%esp, %ebp

	subl	$4, %esp				# Obtener espacio para variable local
	movl	$0, -4(%ebp)			# Mover 0 a variable local

	xorl	%eax, %eax				# limpia el registro eax
	xorl	%ebx, %ebx				# limpia el registro ebx
	xorl	%edi, %edi				# limpia el registro edi

	movl	8(%ebp), %ebx			# direccion del texto
									# que se quiere imprimir
	movb	(%ebx, %edi, 1), %dl	# primer caracter de la cadena
  
printf_imp:
	cmpb	$0, %dl					# fin de la cadena
	je		printf_final			# salto al final de la funcion

	movb	%dl, -4(%ebp)			# caracter a imprimir
	movl	$1, %edx 				# longitud del caracter

	movl	%ebp, %ecx				# direccion del caracter a imprimir
	subl	$4, %ecx				# en ebp menos 4

	movl	$STDOUT, %ebx			# identificador de archivo (stdout)
	movl	$WRITE, %eax			# sys_write (=4)
	int		$0x80					# llamada a interrupcion de software
  
	incl	%edi					# incremento de edi
	movl	8(%ebp), %ebx			# carga la direccion del texto a imprimir
	movb	(%ebx, %edi, 1), %dl	# siguiente caracter de la cadena
	jmp		printf_imp				# salto a inicio del bucle

printf_final:
	movl	%ebp, %esp
	popl	%ebp
	ret

  # ___________________________________________________________________________
  # caracter_int ( caracter )
  # Transforma solo un caracter a numero
 .type caracter_int, @function 
caracter_int:			
	pushl	%ebp  
	movl	%esp, %ebp

	xorl	%eax, %eax				# limpia el registro eax
	movl	8(%ebp), %eax			# carga el parametro de la funcion en eax

	cmp		$48, %eax				# se compara si el caracter es un número
									# menor a cero
	jl		caracter_int_error		# el caracter no es convertible
	cmpl	$57, %eax				# compara si el caracter es un número 
									# mayor que nueve
	jg		caracter_int_error		# el caracter no es convertible
    
	subl	$48, %eax				# convierte el caracter numerico a número 
	jmp		caracter_int_fin		# salto al final del método

caracter_int_error:
	movl $-1, %eax					# indica que el caracter no es numerico

caracter_int_fin:
	movl %ebp, %esp		
	popl %ebp
	ret

  # ___________________________________________________________________________
  # string_int ( cadena )
  # Transforma una cadena de caracteres a numero
  .type string_int, @function 
string_int:
	pushl %ebp
	movl %esp, %ebp

	xorl	%ecx, %ecx				# limpia el registro ecx
	xorl	%edx, %edx				# limpia el registro edx
	xorl	%edi, %edi				# limpia el registro edi
	movl	8(%ebp), %ebx   		# carga el parametro de la funcion en ebx
	movb	(%ebx, %edi, 1), %dl	# carga el primer caracter de la cadena

string_int_while:
	cmpb	$0, %dl					# final de la cadena
	je		string_int_ultimo		# salto a la etiqueta "ultimo"
	pushl	%edx					# carga el caracter que se decea convertir
	call	caracter_int			# llamada a la funcion convertir caracter
	addl	$4, %esp				# se libera el espacio asignado en la pila

	cmpl	$-1, %eax				# si el caracter no fue convertible
	je		string_int_final		# salto al final de la funcion

	imull	$10, %ecx				# multiplica el resultado almacenado
									# para agregar el nuevo digito
	addl	%eax, %ecx				# se agrega el nuevo digito al total
	
	incl	%edi					# incrementa del indice del while
	movb	(%ebx, %edi, 1), %dl 	# se actualiza el nuevo caracter
	jmp		string_int_while		# salto al inicio del while

string_int_ultimo:
	movl	%ecx, %eax				# transferencia de resultado final a eax

string_int_final:
	movl	%ebp, %esp
	popl	%ebp
	ret

  # ___________________________________________________________________________
  # printN ( int )
  # Imprime un numero en la consola
.type printN, @function
printN:
	pushl	%ebp  
	movl	%esp, %ebp
	
	xorl	%eax, %eax				# limpia el registro eax
	xorl	%ecx, %ecx				# limpia el registro ecx	
	xorl	%edi, %edi				# limpia el registro edi       

	movl	ARG1(%ebp), %eax		# carga el parametro de la funcion en eax
	movl	%ebp, %edi				# respaldo de ebp

	xorl	%ebp, %ebp				# limpia el registro ebp
 
printn_to_string: 					# convertir de numero a string
	movl	$10, %ecx		
	xorl	%edx, %edx				# limpia el registro %edx
	cmpl	%eax, %ecx		
	jg		printn_ult_d			# salta si el numero < 10 
	divl	%ecx					# divide el numero entre 10
	addl	$48, %edx				# suma 48 al residuo para obtener
									# el valor en ascii
	push	%edx					# inserta el nuevo caracter en la pila
	inc		%ebp					# incrementa el contador de la pila
	jmp		printn_to_string		# retorna al inicio (to_string)
	
printn_ult_d:						# ultimo digito
	addl	$48, %eax				# suma 48 al ultimo digito para 
									# convertirlo a ascii
	push	%eax					# se inserta el caracter en la pila
	incl	%ebp					# incrementa el contador de pila

printn_num:							# imprimir en consola la cadena en la pila
	xorl	%ebx, %ebx				# limpia el registro %ebx
	cmpl	%ebp, %ebx				# comprueba si aun se deben 
									# sacar elementos de la pila
	jz		printn_fin				# si ya no quedan elementos, salta a fin
	pop		%edx					# extrae un caracter de la pila
	dec		%ebp					# disminuye el contador de elementos en la pila

	movl	%edx, number			# envia el caracter a memoria
	movl	$WRITE, %eax			# SYS_WRITE(4)
	movl	$STDOUT, %ebx			# STD_OUT(1)
	movl	$number, %ecx			# copia el caracter a %ecx
	movl	$1, %edx				# tamaño de caracter en %edx
	int		$SYSCALL				# llamada a interrupcion de linux

	jmp		printn_num				# salto a print_num para imprimir
									# los demas caracteres
printn_fin:
	movl	%edi, %esp
	popl	%ebp
	ret

  # ___________________________________________________________________________
  # ayuda ( )
  # Muestra la ayuda en consola
  .type ayuda, @function 
ayuda:
	pushl %ebp
	movl %esp, %ebp

	pushl	$TEXTO_AYUDA			# Enviar texto de ayuda como parametro
	call	printf					# Imprimir texto
	addl	$4, %esp				# Liberar espacio de parametro

	movl	%ebp, %esp
	popl	%ebp
	ret

  # FIN DEL PROGRAMA #
