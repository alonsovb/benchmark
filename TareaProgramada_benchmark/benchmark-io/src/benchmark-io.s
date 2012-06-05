###############################################################################
#                                                                             #
#                                                                             #
#  benchmark-io - Programa de benchmarking de lecturas a memoria secundaria   #
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
#  Uso:  ./benchmark-io n                                                     #
#                                                                             #
#  n:    Valor que define la cantidad de veces que seran ejecutadas las       #
#        instrucciones                                                        #
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

	# Opciones de apertura de archivos
	.equ READ_ONLY, 0			# Solo lectura
	.equ CREAT_WR_TRUNC, 03101	# Crear si no existe, escritura,
								# truncar si existe
	.equ DEFAULT_PER, 0666		# Permiso por defecto

	# Mensajes de error del programa
	ERR_PARAMETROS:	.ascii	"- La cantidad de parametros no es correcta\n\0"
	ERR_ARCHIVO:	.ascii	"- Error en el archivo temporal\n\0"
	ERR_ITERACION:	.ascii	"- El valor de iteraciones no es correcto\n\0"
	# Mensaje de ayuda
	TEXTO_AYUDA:	.ascii	"- Uso del programa: \n./benchmark n archivo\n"
	.ascii	"\tn : cantidad de instrucciones\n"
	.ascii	"\tarchivo: archivo temporal en el que se leera/escribira\n\0"
	# Valor escrito en el archivo temporal
	CARACTER:		.ascii " \0"
	# Texto de resultado
	TEXTO_RES1:		.ascii	"Total de lecturas y escrituras realizadas: \0"
	TEXTO_RES2:		.ascii	".\n\0"
	# Espacio para almacenar numero textual en funcion printN
	number: 		.ascii	"\0"		# almacena el caracter a imprimir

.bss
	.lcomm BUFFER, 1			# Buffer de un byte para lectura de archivo

.section .text

  .global _start

	# Argumentos de entrada del programa
	.equ	ARGC, 0				# Cuenta de argumentos
	.equ	P_N_PROGRAM, 4		# Nombre del programa
	.equ	P_ITERACION, 8		# Valor de n
	.equ	P_ARCHIVO, 12		# Archivo de salida temporal

	# Variables locales de n y de archivo
	.equ 	ITERACIONES, -4		# Desplazamiento en entero
	.equ 	ARCHIVO_FD, -8		# FD del archivo temporal en escritura
	.equ 	ARCHIVOS_FD, -12	# FD del archivo temporal en lectura

_start:
	movl	%esp, %ebp

	# Variables locales
	subl	$12, %esp				# Espacio para las variables nuevas

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

	# Abrir y revisar el archivo temporal en modo escritura
	movl	$OPEN, %eax				# Codigo de apertura
	movl	P_ARCHIVO(%ebp), %ebx	# Enviar nombre de archivo
	movl	$03101, %ecx			# Abrir en escritura, crear, truncar
	movl	$0666, %edx				# Permisos por defecto
	int		$SYSCALL				# Llamada a sistema

	cmpl	$0, %eax				# Comprobar si se abrio correctamente
	jle		start_error_archivo		# Se salta a error si no fue asi
	movl	%eax, ARCHIVO_FD(%ebp)	# Guardar el codigo de archivo

	# Abrir archivo temporal en modo lectura
	movl	$OPEN, %eax				# Codigo de apertura
	movl	P_ARCHIVO(%ebp), %ebx	# Enviar nombre de archivo
	movl	$READ_ONLY, %ecx		# Abrir en solo lectura
	movl	$DEFAULT_PER, %edx		# Permisos por defecto
	int		$SYSCALL				# Llamada a sistema

	cmpl	$0, %eax				# Comprobar si se abrio correctamente
	jle		start_error_archivo		# Se salta a error si no fue asi
	movl	%eax, ARCHIVOS_FD(%ebp)	# Guardar el codigo de archivo

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

	# Escribir un byte al archivo
	movl	$WRITE, %eax			# Codigo de escritura
	movl	ARCHIVO_FD(%ebp), %ebx	# Enviar el archivo de salida
	movl	$CARACTER, %ecx			# Enviar direccion de la cadena
	movl	$1, %edx				# Un solo caracter
	int		$SYSCALL				# Llamada al sistema

	# Leer un byte del archivo
	movl	$READ, %eax				# Codigo de escritura
	movl	ARCHIVOS_FD(%ebp), %ebx	# Enviar el archivo de salida
	movl	$BUFFER, %ecx			# Enviar direccion de la cadena
	movl	$1, %edx				# Un solo caracter
	int		$SYSCALL				# Llamada al sistema

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

start_error_archivo:
	pushl	$ERR_ARCHIVO			# Enviar texto error de archivo
	call	printf					# Imprimir ese texto
	addl	$4, %esp				# Liberar espacio de parametro
	call	ayuda					# Mostrar texto de ayuda
	movl	$3, %ebx				# Error en el archivo temporal
	jmp		start_fin				# Ir al fin del programa

start_ok:
	pushl	%eax					# Respaldar total de iteraciones
	pushl	%eax					

	# Imprimir texto de resultado inicial
	pushl	$TEXTO_RES1
	call	printf
	addl	$4, %esp

	# Mostrar total de lecturas/escrituras
	popl	%eax
	pushl	%eax
	call	printN
	addl	$4, %esp

	# Imprimir final del texto de resultado
	pushl	$TEXTO_RES2
	call	printf
	addl	$4, %esp
	movl	$0, %ebx				# No hay errores
start_fin:

	pushl	%ebx					# Guardar valor de salida

	# Cerrar fds de archivo temporal
	movl	$CLOSE, %eax			# Codigo de cerrado
	movl	ARCHIVO_FD(%ebp), %ebx	# Codigo de archivo
	int		$SYSCALL				# Llamada a sistema

	movl	$CLOSE, %eax			# Codigo de cerrado
	movl	ARCHIVOS_FD(%ebp), %ebx	# Codigo de archivo
	int		$SYSCALL				# Llamada a sistema

	# Eliminar archivo
	movl	$UNLINK, %eax			# Codigo de eliminado
	movl	P_ARCHIVO(%ebp), %ebx	# Archivo a eliminar
	int		$SYSCALL				# Llamada a sistema

	popl	%ebx					# Retornar valor de salida

	# Finalizar programa
	movl	$1, %eax				# Codigo de salida
	int		$SYSCALL				# Llamada a sistema

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

	movl	$1, %ebx				# identificador de archivo (stdout)
	movl	$4, %eax				# sys_write (=4)
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

