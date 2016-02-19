# Función para averiguar la cantidad de alumnos del vector DNIs.
function cantAlumnos(vectorDNIs) {
	for(dni in vectorDNIs) {
		if(vectorDNIs[dni] != 0) {
			cant++;
		}
	}
	return cant;
}

# Función para validar cada línea del archivo
function validarLinea() {
	# Chequeamos que tengamos la cantidad correcta de campos.
	if(NF == 4) {
		# $1 representa el número de parcial: entero positivo que comienza en 1
		# y termina en "cantidadParciales" (definido en BEGIN).
		if($1 !~ /^[0-9]+$/ || $1 < 1 || $1 > cantidadParciales ) {
			mostrarError(1, "Parcial: Se esperaba un entero entre 1 y "cantidadParciales);
			# Siendo que el DNI ya no es válido, lo ignoramos por el resto del
			# script para evitar "contaminar" resultados.
			if(!$3 in dnis) {
				ignorarDNI();
			}
			return 0;
		}
		# $2 representa el nombre del alumno: no podemos validar mucho puesto
		# que no es un campo "normalizado" desde la consigna, lo que si podemos
		# validar es que sea una cadena de caracteres sin números.
		if($2 !~ /^[a-zA-ZáéíóúÁÉÍÓÚüÜ]+[a-zA-ZáéíóúÁÉÍÓÚüÜ ,\.'-]*$/) {
			mostrarError(2, "Nombre: Se esperaba un nombre");
			return 0;
		}
		# $3 representa el DNI: entero positivo que empieza por 1-9, y continúa
		# con 6 o 7 dígitos.
		if($3 !~ /^[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]?$/) {
			mostrarError(3, "DNI: Se esperaba un entero entre 1000000 y 99999999");
			return 0;
		}

		# $4 representa la nota del parcial: entero positivo de dos dígitos,
		# entre 1 y 10.
		if($4 !~ /^[0-9][0-9]?$/ || $4 <= 0 || $4 > 10) {
			mostrarError(4, "Nota: Se esperaba un entero entre 1 y 10");
			return 0;
		}
		} else {
			mostrarError("", "Cantidad incorrecta de campos o separador");
			return 0;
		}
	# Llegados a este punto asumimos como válida la línea.
	return 1;
}


# Función para "bloquear" o ignorar un DNI. Lo ponemos en lista negra por si
# vuelve a aparecer más tarde, y borramos todos los registros asociados al mismo
# en el array usado para los reportes.
function ignorarDNI() {
	dnis[$3] = 0; # Ingresamos en la lista negra.
	delete alumnos[$3, 0]; # Borramos el nombre de la lista real.
	delete alumnos[$3, 1]; # Borramos el primer parcial de la lista real.
	delete alumnos[$3, 2]; # Borramos el segundo parcial de la lista real.
}
# Función para mostrar mensaje de error.
function mostrarError(campo, msg) {
	printf("[Advertencia: línea %d] ", NR) > "/dev/stderr";
	if(campo != "") {
		printf("(campo %d) ", campo) > "/dev/stderr";
	}
	if(msg != "") {
		printf("%s", msg) > "/dev/stderr";
	}
	printf(".\n") > "/dev/stderr";
}

#########################################################################################################
##########################################INCIALIZACIÓN DE AWK.##########################################
#########################################################################################################
BEGIN {
cantidadParciales = 2;
}
# CUERPO DE AWK: procesamos los datos.
{
# Validamos la línea: NO interrumpimos el proceso, sino que ignoramos la
# línea si no es válida (no respeta el formato de entrada). En particular,
# si aparece un parcial que no sea 1 ó 2, se ignora permanentemente ese DNI
# por el resto del script; y si aparecen más de dos parciales, se hace lo
# mismo para no trabajar con datos "contaminados".
if(validarLinea() != 0) {
# Guardamos los campos en variables con nombres más "amigables", para
# hacer más legible el script.
nroParcial = $1;
nombre = $2;
dni = $3;
nota = $4;
# Mantenemos un array asociativo de manera tal que el índice sea el
# DNI del alumno y, 0 para el nombre, 1 para el primer parcial y 2 para
# el segundo parcial:
# alumnos[dni, 0] = nombre del alumno
# alumnos[dni, 1] = nota del primer parcial
# alumnos[dni, 2] = nota del segundo parcial
# y también mantenemos un array para los ignorar los registros erróneos
# (con más de 2 parciales):
# dnis[dni] = 0 (ignorado) | 1 (válido)
if(dni in dnis && dnis[dni] == 0) {
# Si es un DNI en lista negra, ignoramos la línea.
next;
} else {
if((dni, 0) in alumnos) {
if((dni, 1) in alumnos && nroParcial == 1 ||
(dni, 2) in alumnos && nroParcial == 2 ) {
# Si el DNI existe en nuestra lista regular, y ya tenemos
# los dos parciales, es un error. Informamos el error, y
# bloqueamos el DNI para seguir procesando.
mostrarError("","El alumno tiene más de dos parciales");
ignorarDNI();
} else {
# Si solamente tiene una nota, asignamos la otra.
alumnos[dni, nroParcial] = nota;
}
} else {
# Si es un nuevo alumno, guardamos el nombre y la nota, y lo
# ingresamos a la lista de DNIs.
dnis[dni] = 1;
alumnos[dni, 0] = nombre;
alumnos[dni, nroParcial] = nota;
}
}
} else {
# Ignorar líneas erróneas o en blanco.
}
}
# FINALIZACIÓN DE AWK: mostramos resultados.
END {
# Validamos que haya al menos un registro sobre el cuál podamos mostrar
# cualquier tipo de reporte, mediante el conteo de DNIs válidos.
if((cantidadAlumnos = cantAlumnos(dnis)) != 0) {
if (parametro == "-p") {
# Si el parámetro es para reporte de parciales.
# Mostramos la cantidad total de alumnos.
print "Alumnos: "cantidadAlumnos;
# Por cada alumno obtenemos las estadísticas. Para esto nos valemos
# nuevamente de un array asociativo de modo que:
# parciales[nroParcial, "aprobada"] =
# cantidad de alumnos con 7 o más en nroParcial.
# parciales[nroParcial, "desaprobada"] =
# cantidad de alumnos con menos de 4 en nroParcial.
# parciales[nroParcial, "cursada"] =
# cantidad de alumnos con 4 o menos de 7 en nroParcial.
# parciales[nroParcial, "sumatoria"] =
# sumatoria de notas en nroParcial.
# parciales[nroParcial, "presentes"] =
# cantidad de alumnos presentes en nroParcial.
for(dni in dnis) { # Por cada DNI.
if(dnis[dni] != 0) { # Si es un DNI válido (no ignorado).
for(j = 1; j <= cantidadParciales; j++) { # Por cada parcial.
if((dni, j) in alumnos) { # Si el alumno lo rindió.
# Actualizamos la estádistica.
if(alumnos[dni, j] >= 7) {
parciales[j, "aprobada"]++;
} else {
if(alumnos[dni, j] < 4) {
parciales[j, "desaprobada"]++;
} else {
parciales[j, "cursada"]++;
}
}
# Guardamos la sumatoria y asistencias.
parciales[j, "sumatoria"] += alumnos[dni, j];
parciales[j, "presentes"]++;
}
}
}
}
# Mostramos los resultados por cada parcial.
for(i = 1; i <= cantidadParciales; i++) {
printf("Parcial %d: ", i);
printf("Promoción: %d, ", parciales[i, "aprobada"]);
printf("Entre 4 y 6: %d, ", parciales[i, "cursada"]);
printf("Desaprobados: %d, ", parciales[i, "desaprobada"]);
promedio = parciales[i, "sumatoria"] / parciales[i, "presentes"];
printf("Promedio: %.2f.\n", promedio);
}
} else {
if(parametro == "-a" && dni_parametro == "") {
# Si el parámetro es para reporte general de alumnos.
for(dni in dnis) { # Por cada DNI.
if(dnis[dni] != 0) { # Si el DNI es válido (no ignorado).
cantidadAsistencias = 0;
sumatoriaNotas = 0;
condicionFinal = "";
for(j = 1; j <= cantidadParciales; j++) { # Por cada parcial.
if((dni, j) in alumnos) { # Si el alumno lo rindió.
# Obtenemos las asistencias y la sumatoria.
cantidadAsistencias++;
sumatoriaNotas = sumatoriaNotas + alumnos[dni, j];
}
}
# Calculamos el promedio y la condición del alumno.
if(cantidadAsistencias != cantidadParciales) {
condicionFinal = "Materia desaprobada"
}
promedio = sumatoriaNotas / cantidadAsistencias;
if(condicionFinal != "Materia desaprobada") {
if(promedio >= 7) {
condicionFinal = "Materia aprobada";
} else {
if(promedio < 4) {
condicionFinal = "Materia desaprobada";
} else {
condicionFinal = "Materia cursada";
}
}
}
# Mostramos los datos del alumno.
printf("%s, ", alumnos[dni, 0]);
printf("DNI: %d, ", dni);
printf("%s, ", condicionFinal);
printf("Promedio: %.2f.\n", promedio);
}
}
} else {
# Si el parámetro es para reporte de un alumno en particular.
if(dni_parametro in dnis && dnis[dni_parametro] != 0) {
# Si el DNI está y es válido (no ignorado).
dni = dni_parametro; # Para hacer más legible el script.
cantidadAsistencias = 0;
sumatoriaNotas = 0;
condicionFinal = "";
# Mostramos los datos del alumno.
printf("Alumno: %s, DNI: %d\n", alumnos[dni, 0], dni);
# Mostramos el encabezado del reporte.
printf("Parcial\t\tNota\n");
# Recorremos todos los parciales buscando las notas del alumno.
for(i = 1; i <= cantidadParciales; i++) { # Por cada parcial.
if((dni, i) in alumnos) { # Si el alumno lo rindió.
# Obtenemos las asistencias y la sumatoria.
cantidadAsistencias++;
sumatoriaNotas = sumatoriaNotas + alumnos[dni, i];
# Mostramos si existe una nota para dicho parcial.
printf("%7d\t\t%-4d\n", i, alumnos[dni, i]);
} else {
# O mostramos si estuvo ausente a dicho parcial.
printf("%7d\t\tAusente\n", i);
}
}
# Calculamos el promedio y la condición del alumno.
if(cantidadAsistencias != cantidadParciales) {
condicionFinal = "Materia desaprobada"
}
promedio = sumatoriaNotas / cantidadAsistencias;
if(condicionFinal != "Materia desaprobada") {
if(promedio >= 7) {
condicionFinal = "Materia aprobada";
} else {
if(promedio < 4) {
condicionFinal = "Materia desaprobada";
} else {
condicionFinal = "Materia cursada";
}
}
}
# Mostramos el promedio y la condición final.
printf("Promedio: %.2f. %s.\n", promedio, condicionFinal);
} else {
print "El DNI ingresado no existe o es inválido."
}
}
}
} else {
print "No hay registros válidos suficientes para realizar un reporte."
}
}
# EOF
