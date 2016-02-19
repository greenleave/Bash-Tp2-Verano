#!/bin/bash

#path_sin_espacios=$1
#path_sin_espacios=${path_sin_espacios/" "/"\ "}
#path=${path_sin_espacios[0]}${path_sin_espacios[1]}
#echo "aaaaaa" $path
#echo "path sin espacios: $path_sin_espacios"
#set $path $2 $3 $4 $5 $6
#echo $path_sin_espacios
#echo $#
#echo '$1: ' "$1"
#echo $1
#echo $2
#echo $3

# Descripción: Este script toma como parámetro la ruta de un archivo regular y lo
# procesa mediante un script de AWK de acuerdo a lo solicitado en la
# consigna.
# Función para mostrar texto tabulado.
echot() {
tabs=""
# Creamos una cadena con n-tabulaciones al principio.
for ((i = 0; i < $1; i++)); do
tabs="$tabs "
done
# Mostramos el mensaje tabulado.
echo -e "$tabs$2"
}
# Función para mostrar una sugerencia en caso de que los parámetros ingresados
# no sean los esperados.
errorLlamada() {
	# El error siempre contiene la siguiente cadena.
	msg="¡Ha ocurrido un Error en la llamada!"
	# Si además existe un mensaje particular, lo incorporamos a la cadena.
	if [[ $# -eq 1 ]]; then
		msg="$msg $1"
	fi
	# Mostramos el mensaje y la sugerencia a utilizar la ayuda.
	echo "$msg" >&2
	echo "Para ver la ayuda, use $0 [-?|--help|-h]." >&2
	exit 1
}
# Función para mostrar errores más generales.
error() {
	echo $1 >&2
	exit 1
}

# Función para mostrar la ayuda en caso que la solicite el usuario.
ayuda() {
echo "Este script toma un archivo por parámetro que contenga las notas de los"
echo "alumnos, una por línea, con el formato:"
echot 1 "parcial_nro, alumno_nombre, alumno_dni, nota"
echo "y muestra un informe de acuerdo a las opciones pasadas también por"
echo "parámetro."
echo
echo "Uso: $0 <archivo> (-p | -a [<dni>)"
echot 1 "Donde <archivo> es el archivo a procesar que contiene el las notas."
echot 1 "Y <dni> es el DNI de algún alumno."
echo
echo "Opciones:"
echot 2 "-p: reporte de parciales."
echot 2 "-a: reporte de alumnos."
echot 2 "-a <dni>: consulta de alumno."
echot 2 "-?: muestra ésta ayuda."
echo
echo "Ejemplos:"
echot 1 "$0 alumnos.txt -p"
echot 1 "$0 alumnos.txt -a"
echot 1 "$0 alumnos.txt -a 30330333"
echot 1 "$0 '/root/Desktop/Ejercicio 4/alumnos.txt -a 30330333"
}

# Verificamos si el usuario solicitó ayuda.
if [[ $1 == "-?" || $1 == "-h" || $1 == "--help" ]] ; then
	# Mostramos la ayuda y salimos.
	ayuda
	exit 0
fi

# Si no solicitó ayuda procedemos a procesar los parámetros.
# Procesamos primero parámetro del archivo con las notas.
archivo="$1"
IFS=";"
echo "$archivo"
if [[ -z "$archivo" ]]; then
	# Si nunca se pasó un archivo, mostramos el error y abortamos.
	errorLlamada "Debe proveer al menos un archivo para procesar."
else
	# ¿No tenemos permisos de lectura sobre el archivo?
	if [[ !(-r $archivo) ]]; then
		#si contiene el path espaciado
		if [[ !($archivo == "\ ") ]]; then
			echo "archivo espaciado"
		#fi;
		# ¿Es porque el archivo no existe?
		#if [[ !(-e $archivo) ]]; then
		#	# No existe, mostramos el error y abortamos.
		#	error "El archivo $archivo no existe."
	else
		# No tenemos permisos de lectura, mostramos el error y abortamos.
		error "No tiene permisos de lectura sobre $archivo."
	fi
else
# Tenemos permisos de lectura. Tratamos de obtener el nombre completo
# del archivo.
archivo=$(readlink -f $archivo)
# ¿No es un archivo regular?
if [[ !(-f $archivo) ]]; then
# No es un archivo regular, mostramos el error y abortamos.
error "$archivo no es un archivo."
else
# Tratamos de obtener el tipo de archivo.
tipoArchivo=$(mimetype --output-format %m $archivo)
regex="^text/"
# ¿Es un archivo de texto?
if [[ !($tipoArchivo =~ $regex) ]]; then
# No es un archivo de texto, mostramos el error y abortamos.
error "$archivo debe ser un archivo de texto."
fi
fi
fi
fi

# Acto seguido, tratamos de procesar el resto de los parámetros.
param=
dni=
if [[ "$2" != "-a" && "$2" != "-p" ]]; then
# Si se pasó una opción no válida, mostramos el error y abortamos.
errorLlamada "Opción no válida, debe proveer -p o -a."
else
if [[ "$2" == "-a" && ! -z "$3" ]]; then
	# Si se pasó la opción '-a' tratamos de obtener el DNI.
	regex="^[1-9][0-9]{6,7}$"
	if [[ !($3 =~ $regex) ]]; then
		# Opción '-a' con un DNI no válido, mostramos el error y abortamos.
		errorLlamada "La opción -a requiere un DNI."
	else
		# Caso contrario, guardamos el DNI.
		dni=$3
	fi
fi
# Guardamos el parámetro del tipo de reporte.
param=$2
fi
# Invocamos a AWK para procesar el archivo de notas.
awk -F ", " -v parametro=$param -v dni_parametro=$dni -f alumnos.awk $1
# EOF
