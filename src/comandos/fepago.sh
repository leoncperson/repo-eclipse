#!/bin/bash
MSG="./glog"                 #Nombre del script que imprime mensajes en archivo de log
#constantes
FEPAGO_PATH_LOG="glog fepago"
A_PAGAR="A PAGAR"
FILE_APAGAR="$GRUPO/facturas/apagar.txt"
FILE_PRESU="$GRUPO/pp/presu.txt"
PREFIX_APAGAR_VERSION="$GRUPO/facturas/old/apagar."
VERSION_APAGAR="$GRUPO/facturas/old/version_apagar.dat"
FILE_APAGAR_TEMP="$GRUPO/facturas/old/apagar.tmp"
FILE_APAGAR_COMPROMET="$GRUPO/facturas/old/apagar.txt.tmp"
PREFIX_PRESU_VERSION="$GRUPO/pp/old/presu."
VERSION_PRESU="$GRUPO/facturas/old/version_presu.dat"
FILE_PRESU_TEMP="$GRUPO/pp/old/presu.tmp"
#varibles globales
gLineaFactura=""
gCodigoCAE=
gFechaVenc=
gMontoPag=
gEstadoFac=
gNumLineFac=0
#parametros globales de entrada
gFechaDesde=
gFechaHasta=
gMontoDesde=
gMontoHasta=
#parametros globales de presupuesto
gMontoFuente=
#modo de corrida
gOptModo=
gOptBarrido=
#nro de version
gNroVersionPresu=0
gNroVersionAPagar=0
LIST_FUENTES=(11 0.0 0.0 #fuente 11
12 0.0 0.0 #fuente 12
13 0.0 0.0 #fuente 13
14 0.0 0.0 #fuente 14
15 0.0 0.0 ) #fuente 15
export GRUPO=$PWD
function existeFepago
{
	#ver si existe otro fepago corriendo
	CNTPROC=`ps -a | grep -c fepago`
	CURRENTPID=0
#	obtenerPID
#	echo "is $CURRENTPID"
#	echo $CNTPROC
#	PID=`ps -e | grep -c "fefago"`
	#Si se encuentra que se ha ejecutado.
	if [ $CNTPROC -gt 2 ]; then
#	if [ -n "$PID" ]; then
		$FEPAGO_PATH_LOG "Se ha encontrado una instancia previa del programa fepago" "E"
		echo "Se ha encontrado una instancia previa del programa fepago"
		exit 1
	fi
}
function existeFeprima
{
	#ver si existe otro fepago corriendo
	CNTPROC=`ps -a | grep -c feprima`
	CURRENTPID=0
#	obtenerPID
#	echo "is $CURRENTPID"
#	echo $CNTPROC
#	PID=`ps -e | grep -c "fefago"`
	#Si se encuentra que se ha ejecutado.
	if [ $CNTPROC -gt 2 ]; then
#	if [ -n "$PID" ]; then
		$FEPAGO_PATH_LOG "Se ha encontrado una instancia previa del programa feprima" "E"
		echo "Se ha encontrado una instancia previa del programa feprima"
		exit 1
	fi
}
function obtenerPID
{
	ps x > auxiliar.txt
 	export GREP_OPTIONS="--color=always"
	RES=`grep "bash $1" auxiliar.txt|cut -f2 -d" "`
	cat auxiliar.txt
	echo $RES
	PID=`grep "bash $1" auxiliar.txt|cut -f2 -d" "`
	#echo $1
	rm auxiliar.txt
	if [ -n $PID ] ; then
		CURRENTPID=$PID
		#echo $PID # Muestra el PID por stdout
	fi
}
function checkVariablesAmbiente(){
   #export GRUPO
   #export PATH_ARCH_MAEPRO
   #export PATH_ARCH_PRESU
   #export PATH_PRESU_OLD
   #export PATH_ARRIBOS
   #export PATH_FACT_RECIBIDAS
   #export PATH_FACT_RECHAZADAS
   #export PATH_FACT_ACEPTADAS
   #export PATH_ARCH_FACT_PAGAR
   #export PATH_ARCH_FACT_PAGAR_OLD
   #export PATH_LISTADOS
   #export PATH_LOG
   #export PATH_COMANDOS
	#Se ha seteado la var GRUPO?
	if test -z $GRUPO
	then
		return 1
	fi
	#Se ha seteado la var PATH_ARCH_MAEPRO?
	if test -z $PATH_ARCH_MAEPRO
	then
		return 1
	fi
	#Se ha seteado la var PATH_ARCH_PRESU?
	if test -z $PATH_ARCH_PRESU
	then
		return 1
	fi
	
	#Se ha seteado la var PATH_PRESU_OLD?
	if test -z $PATH_PRESU_OLD
	then
		return 1
	fi
	#Se ha seteado la var PATH_ARRIBOS?
	if test -z $PATH_ARRIBOS
	then
		return 1
	fi
	#Se ha seteado la var PATH_FACT_RECIBIDAS?
	if test -z $PATH_FACT_RECIBIDAS
	then
		return 1
	fi
	
	#Se ha seteado la var PATH_FACT_RECHAZADAS?
	if test -z $PATH_FACT_RECHAZADAS
	then
		return 1
	fi	
	#Se ha seteado la var PATH_FACT_ACEPTADAS?
	if test -z $PATH_FACT_ACEPTADAS
	then
		return 1
	fi	
	#Se ha seteado la var PATH_ARCH_FACT_PAGAR?
	if test -z $PATH_ARCH_FACT_PAGAR
	then
		return 1
	fi	
	#Se ha seteado la var PATH_ARCH_FACT_PAGAR_OLD?
	if test -z $PATH_ARCH_FACT_PAGAR_OLD
	then
		return 1
	fi	
	#Se ha seteado la var PATH_LISTADOS?
	if test -z $PATH_LISTADOS
	then
		return 1
	fi	
	#Se ha seteado la var PATH_LOG?
	if test -z $PATH_LOG
	then
		return 1
	fi	
	#Se ha seteado la var PATH_COMANDOS?
	if test -z $PATH_COMANDOS
	then
		return 1
	fi	
	
	return 0
}
function mostrarDisponibilidades
{
	CONTADOR=0
	while [ $CONTADOR -lt 15 ]; do
		echo Fuente: ${LIST_FUENTES[$CONTADOR]} Disponibilidad Inicial: ${LIST_FUENTES[$((CONTADOR+1))]} Disponibilidad Final: ${LIST_FUENTES[$((CONTADOR+2))]}
		let CONTADOR=CONTADOR+3
	done
	return 1
}
#muestra los comprometidos luego borra el temporal
function mostrarComprometidos
{
	while read line
	do
		echo $line
	done < $FILE_APAGAR_COMPROMET
	#echo CAE: vencimiento: monto: estadoActualizado:
	rm -f $FILE_APAGAR_COMPROMET
}
#carga el vecto global de fuentes
function loadVectorFuentes
{
	CONTADOR=0
	while [ $CONTADOR -lt 15 ]; do
		nroFte=${LIST_FUENTES[$CONTADOR]}
		getMontoxFuente $FILE_PRESU $nroFte
		#valor inicial
		LIST_FUENTES[$((CONTADOR+1))]=$gMontoFuente
		#valor final por ahora
		LIST_FUENTES[$((CONTADOR+2))]=$gMontoFuente
		let CONTADOR=CONTADOR+3
	done
	return 1
}
	
# $1 nro de fuente
# $2 valor inicial a cargar
function loadFuenteInicial
{
	CONTADOR=$1
	CONTADOR=$((CONTADOR-11))
	valor=$2
	LIST_FUENTES[$((CONTADOR+1))]=$valor
}
# $1 nro de fuente
# $2 valor final a cargar
function loadFuenteFinal
{
	CONTADOR=$1
	CONTADOR=$((CONTADOR-11))
	valor=$2
	LIST_FUENTES[$((CONTADOR+2))]=$valor
}
# $1 nombre del archivo
# $2 nro de fuente a buscar
#si la fuente no existe retorna 0
function getMontoxFuente
{
#linea de presu.txt
#fuente;montoDisponible;fechaUltModif;userUltModif
	fuente=$2
	while read line
	do 
		fuenteLine=`echo "$line" | sed "s/^\([0-9]\{2\}\);.*/\1/"`	   
		montoDispo=`echo "$line" | sed "s/^\([0-9]\{2\}\);\([0-9]*\.[0-9]\{2\}\);.*/\2/"`	   
		if [ "$fuente" = "$fuenteLine" ]
		then
			gMontoFuente=$montoDispo
			return 1
		fi
	done < $1
	return 0
}
#checkea la disponibilidad contra el archivo de
#presupuesto
# $1 monto de disponibilidad
function checkDispo
{
	montoPag=$1
	getFuenteByRango $montoPag
	nroFte=$?
	getMontoxFuente $FILE_PRESU $nroFte
	if [ $? -eq 1 ] ; then
		montoFte=$gMontoFuente
		if [ `echo "$montoPag > $montoFte" | bc -l` = "1" ]; then
			return 0
		else
			return 1
		fi	
	else
		#la fuente no existe
		$FEPAGO_PATH_LOG "El numero de fuente no existe en el archivo presu.txt" "E"
	fi
}
# $1 valor a restar de la disponibilidad
function updateDispo
{
	montoPag=$1
	getFuenteByRango $montoPag
	nroFte=$?
	getMontoxFuente $FILE_PRESU $nroFte
	if [ $? -eq 1 ] ; then
		montoFte=$gMontoFuente
		if [ `echo "$montoPag > $montoFte" | bc -l` = "1" ]; then
			return 0
		else
			diferMonto=`echo "$montoFte-$montoPag" | bc`
			sed $FILE_PRESU -e "s/$nroFte;\([0-9]*.[0-9]\{2\}\);/$nroFte;$diferMonto;/g" > $FILE_PRESU_TEMP
			cat $FILE_PRESU_TEMP > $FILE_PRESU
			rm -f $FILE_PRESU_TEMP
			#se actualiza las disponibilidades finales
			loadFuenteFinal $nroFte $diferMonto
			return 1
		fi	
	else
		#la fuente no existe
		$FEPAGO_PATH_LOG "El numero de fuente no existe en el archivo presu.txt	" "E"
	fi
}
# $1 indicador de modificacion de factura
# $2 indica si la linea cumplio con la condicion
function insertTempAPagar
{
	bChange=$2
	if [ $bChange -eq 1 ] ; then
		bUpdateFactura=$1
		if [ $bUpdateFactura -eq 1 ] ; then
			echo "$gCodigoCAE;$gFechaVenc;$gMontoPag;LIBERADA" >> $FILE_APAGAR_TEMP
		else
			echo "$gCodigoCAE;$gFechaVenc;$gMontoPag;A PAGAR" >> $FILE_APAGAR_TEMP
		fi
	else
		echo "$gCodigoCAE;$gFechaVenc;$gMontoPag;$gEstadoFac" >> $FILE_APAGAR_TEMP
	fi
}
#actualiza el archivo de facturas "apagar.txt"
function updateAPagar
{
	#copia y borra el temporal
	mv $FILE_APAGAR_TEMP $FILE_APAGAR
}
# $1 flag de modificacion de linea de factura
# $2 flag de comprometido o NO
#guarda solo las facturas comprometidas
function insertComprometido
{
	bCompromet=$2
	if [ $bCompromet -eq 1 ] ; then
		bUpdateFactura=$1
		if [ $bUpdateFactura -eq 1 ] ; then
			echo "$gCodigoCAE;$gFechaVenc;$gMontoPag;LIBERADA" >> $FILE_APAGAR_COMPROMET
		else
			echo "$gCodigoCAE;$gFechaVenc;$gMontoPag;A PAGAR" >> $FILE_APAGAR_COMPROMET
		fi
	fi
}
# recorre el archivo de facturas
# $1 nombre de archivo
# $2 estado de busqueda
# $3 opt del menu de barrido
function recorrerFacturas
{
	#se borra el temporal por si estaba
	rm -f $FILE_APAGAR_TEMP
	gNumLineFac=0
	#-------------------copia facturas
	nextNroVersion $VERSION_APAGAR
	versionAPagar=$?
	cp $FILE_APAGAR $PREFIX_APAGAR_VERSION$versionAPagar
	#-------------------
	if [ $gOptModo = "Actualizacion" ] ; then
		#-------------------copia presupuesto
		nextNroVersion $VERSION_PRESU
		versionPresu=$?
		cp $FILE_PRESU $PREFIX_PRESU_VERSION$versionPresu
		#-------------------
	fi
	numLine=0	
	estado=$2
	opt=$3
	while read line
	do
		bCompromet=0
		bChange=0
		bUpdateFactura=0
		procFileFacturaAPagar $estado $numLine $line
		# 1ero se filtra por estado "A PAGAR"	
		if [ $? -eq 1 ]; then
			checkCondicion $opt
			# 2do se filtra por la condicion de barrido
			if [ $? -eq 1 ]; then
				bCompromet=1
				if [ $gOptModo = "Actualizacion" ] ; then
					# 3ero se filtra por la disponibilidad
					checkDispo $gMontoPag
					if [ $? -eq 1 ]; then
						updateDispo $gMontoPag
						bUpdateFactura=1
						bChange=1
					fi
#				elif [ $gOptModo = "Simulacion" ] ; then
#					echo ES Simulacion
				fi
			fi
		fi
		#se actualiza apagar.txt
		insertComprometido $bUpdateFactura $bCompromet
		insertTempAPagar $bUpdateFactura $bChange
	done < $1
	updateAPagar
	return 1
}
#recorre el archivo de facturas y busca los registros
# $1 estado a buscar
# $2 numero de linea
# $3 linea a procesar 
#buscar desde el nro de linea global gNumLineFac
function procFileFacturaAPagar
{	
	estado=$1
	numLine=$2
	numLine=$((numLine+1))
	#line=$3
	codigoCAE=`echo "$line" | sed "s/^\([0-9]\{14\}\);.*/\1/"`	   
	fechaVenc=`echo "$line" | sed "s/^\([0-9]\{14\}\);\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\);.*/\2/"`	   
	montoPag=`echo "$line" | sed "s/^\([0-9]\{14\}\);\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\);\([0-9]*\.[0-9]\{2\}\).*/\3/"`   
#	estadoFac=`echo "$line" | sed "s/^\([0-9]\{14\}\);\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\);\([0-9]*\.[0-9]\{2\}\);\([A-Z ]\)/\4/"`
	estadoFac=`echo "$line" | sed "s/^[^;]*;[^;]*;[^;]*;\([^;]*\).*$/\1/"`
# 	estadoFac=`echo "$line" | cut -d";" -f4` `
	if [ `echo "$numLine > $gNumLineFac" | bc -l` = "1" ]; then
		if [ "$estadoFac" = "A PAGAR" ]; then
			gCodigoCAE=$codigoCAE
			gFechaVenc=$fechaVenc
			gMontoPag=$montoPag
			gEstadoFac=$estadoFac
			gNumLineFac=$numLine
			gLineaFactura=$line			
			return 1
		fi
	fi
	return 0
}
# $1 valor a comparar
#retorna el tipo de fuente segun en que rango este el valor
#retorna 0 si  no encuentra ninguna
function getFuenteByRango
{
	valor=$1
	if [ `echo "1000.00 > $valor" | bc -l` = "1" ]; then
		return 11
	fi
	if [ `echo "$valor >= 1000.00 && 10000.00 > $valor" | bc -l` -eq 1 ]; then
		return 12
	fi
	if [ `echo "$valor>=10000.00 && 50000.00>$valor" | bc -l` -eq 1 ]; then	
		return 13
	fi
	if [ `echo "$valor>=50000.00 && 150000.00>$valor" | bc -l` -eq 1 ]; then	
		return 14
	fi
	if [ `echo "$valor>=150000.00" | bc -l` -eq 1 ]; then		
		return 15
	fi
	return 0
}
#controla los parametros de entrada
function mainCheck
{
	checkVariablesAmbiente
	if [ $? -ne 0 ]
	then 
		$FEPAGO_PATH_LOG "Faltan inicializar variables de ambiente" "E"
		#Intento de mover un archivo que no existe en arribos
		exit 0
		#return $retcode 
	fi 
}
#recibe un argumento $1 que contiene la fecha a validar
#retorna 1 si es valida
#retorna 0 si es invalida
function validFecha
{
	fechaV=$1
	fechaV=`echo "$fechaV" | grep "^\(19\|20\)[0-9][0-9]-\(0[1-9]\|1[012]\)-\(0[1-9]\|[12][0-9]\|3[01]\)$"`
 	if test -z $fechaV ; then
 		return 0
	fi
	return 1
}
#recibe un argumento $1 que contiene el monto a validar
#retorna 1 si es valido
#retorna 0 si es invalido
function validMonto
{
	line=$1
	montoTemp=`echo "$line" | grep "^\([0-9]*\.[0-9][0-9]\)$"`
	
	if test -z $montoTemp
	then
		return 0
	fi
	return 1
}
#obtiene la version del archivo
#actualiza el nro de version
#si no existe lo crea
# $1 nombre del archivo donde se guarda el nro de version
function nextNroVersion
{
	nroVersion=0
	archivo=$1
	#si el archivo no existe
	if test -f $archivo
	then
		nroVersion=`head -n 1 $archivo`
	else
		#se crea la version 1
		echo "1">$archivo
	fi
	#se obtiene el nro de version y se actualiza
	echo $((nroVersion+1))>$archivo
	return $nroVersion
}
#esta funcion lee 2 parametros y los valida
#$2 fechaDesde
#$3 fechaHasta
function validRangoFechas
{
	validFecha $1
	if [ $? -eq 1 ]; then
		validFecha $2
		if [ $? -eq 1 ]; then
			#ambas son validas
			fechaDesde=$(echo $1 | cut -d"-" -f1)$(echo $1 | cut -d"-" -f2)$(echo $1 | cut -d"-" -f3)
			fechaHasta=$(echo $2 | cut -d"-" -f1)$(echo $2 | cut -d"-" -f2)$(echo $2 | cut -d"-" -f3)
			#controlar rango
			if [ "$fechaDesde" -le "$fechaHasta" ]; then
				gFechaDesde=$fechaDesde
				gFechaHasta=$fechaHasta
				return 1
			fi			
		fi
	fi
	return 0
}
#esta funcion lee 2 parametros
#$1 montoDesde
#$2 montoHasta
function validRangoMontos
{
	validMonto $1
	if [ $? -eq 1 ]; then	
		validMonto $2
		if [ $? -eq 1 ]; then
			#ambas son validas
			montoDesde=$1
			montoHasta=$2
			#controlar rango
			if [ `echo "$montoDesde > $montoHasta" | bc -l` = "1" ]; then
				return 0
			else
				gMontoDesde=$montoDesde
				gMontoHasta=$montoHasta
				return 1
			fi			
		fi
	fi	
	return 0
	
}
#esta funcion lee de consola 4 parametros
#$1 fechaDesde
#$2 fechaHasta
#$3 montoDesde
#$4 montoHasta
function validRangoFechasMontos
{
	validFecha $1
	if [ $? -eq 1 ]; then
		validFecha $2
		if [ $? -eq 1 ]; then
			validMonto $3
			if [ $? -eq 1 ]; then
				validMonto $4
				if [ $? -eq 1 ]; then
					gFechaDesde=$1
					gFechaHasta=$2
					gMontoDesde=$3
					gMontoHasta=$4
					return 1
				fi
			fi
		fi
	fi
	return 0;
}
#controla la condicion del registro de factura
# $1:opt opcion del menu [Fecha,Importe,Fecha_importe]
function checkCondicion
{
	opt=$1
	if [ "$opt" = "Fechas" ]; then
		#recibe fechaDesde,fechaHasta valorFecha
		checkCondicionFechas $gFechaDesde $gFechaHasta $gFechaVenc
		return $?
	fi
	if [ "$opt" = "Importes" ]; then
		#recibe montoDesde,montoHasta valorMonto
		checkCondicionMontos $gMontoDesde $gMontoHasta $gMontoPag
		return $?
	fi
	if [ "$opt" = "Fechas_Importes" ]; then
		#recibe fechaDesde,fechaHasta valorFecha
		checkCondicionFechas $gFechaDesde $gFechaHasta $gFechaVenc
		#si cumple la condion de fechas
		if [ $? -eq 1 ]; then
			#recibe montoDesde,montoHasta valorMonto
			checkCondicionMontos $gMontoDesde $gMontoHasta $gMontoPag
			return $?			
		else
			return $?
		fi
	fi
	return 0	
}
#esta funcion checkea que el valor este dentro del rango de fecha
# $1:fechaDesde
# $2:fechaHasta
# $3:valorFecha
#retorna 1 si cumple la condicion
#retorna 0 si NO cumple
function checkCondicionFechas
{
	fechaDesde=$1
	fechaHasta=$2
	valorFecha=$(echo $3 | cut -d"-" -f1)$(echo $3 | cut -d"-" -f2)$(echo $3 | cut -d"-" -f3)
	if [ "$fechaDesde" -le "$valorFecha" -a "$valorFecha" -le "$fechaHasta"  ]; then
		return 1
	else
		return 0
	fi
}
#esta funcion checkea que el valor este dentro del rango de montos
# $1:montoDesde
# $2:montoHasta
# $3:valorMonto
#retorna 1 si cumple la condicion
#retorna 0 si NO cumple
function checkCondicionMontos
{
	montoDesde=$1
	montoHasta=$2
	valorMonto=$3
	if [ `echo "$montoDesde  > $valorMonto" | bc` = "1" ]; then
		return 0
	else
		if [ `echo "$valorMonto > $montoHasta" | bc` = "1" ]; then
			return 0
		else
			return 1
		fi
	fi
}
	#muestra un menu de modos
#retorna la opcion elegida
function menuModos
{
	OPCIONES_MODO="Simulacion Actualizacion Salir"
	select opt in $OPCIONES_MODO; do
		if [ "$opt" = "Simulacion" ]; then
			gOptModo="Simulacion"
			return 1
		elif [ "$opt" = "Actualizacion" ]; then
			gOptModo="Actualizacion"
			return 2
		elif [ "$opt" = "Salir" ]; then
			gOptModo="Salir"
			return 100
		else
			#clear
			echo opcion erronea
		fi
	done
}
function menuBarrido
{
	#se presenta el menu
	OPCIONES_BARRIDO="Fechas Importes Fechas_Importes Salir"
	select opt in $OPCIONES_BARRIDO; do
		if [ "$opt" = "Salir" ]; then
			return 0
		elif [ "$opt" = "Fechas" ]; then
			echo "Fechas"
			echo formato AAAA-MM-DD
			echo Ingrese [fechaDesde]
			read fDesde
			echo Ingrese [fechaHasta]
			read fHasta
			validRangoFechas $fDesde $fHasta
			if [ $? -eq 1 ]; then
				gOptBarrido=$opt
				#se graban en el log los parametros de inicio
				$FEPAGO_PATH_LOG "Inicio de fepago: $gOptModo $gOptBarrido $fDesde $fHasta" "I"
				return 1
			else
				echo "ERROR en parametros de entrada"
				$FEPAGO_PATH_LOG "Rango de fechas invalida" "E"
			fi
			#se trabaja con rango de fechas
		elif [ "$opt" = "Importes" ]; then
			echo "Importes"
			echo "Ingrese [montoDesde] [montoHasta]"
			echo "formato XXX X.XX"
			read montoDesde
			read montoHasta
			validRangoMontos $montoDesde $montoHasta
			if [ $? -eq 1 ]; then
				gOptBarrido=$opt
				#se graban en el log los parametros de inicio
				$FEPAGO_PATH_LOG "Inicio de fepago: $gOptModo $gOptBarrido $montoDesde $montoHasta" "I"				
				return 1
			else
				echo "ERROR en parametros de entrada"
				$FEPAGO_PATH_LOG "Rango de importes invalido" "E"
			fi
			#se trabaja con rango de Importes
		elif [ "$opt" = "Fechas_Importes" ]; then
			echo "Fechas_Importes"
			echo Ingrese [fechaDesde] [fechaHasta] [montoDesde] [montoHasta]
			echo formato AAAA-MM-DD XXXXXXXX.XX
			read fDesde
			read fHasta
			read montoDesde
			read montoHasta
			validRangoFechasMontos $fDesde $fHasta $montoDesde $montoHasta
			if [ $? -eq 1 ]; then
				gOptBarrido=$opt
				#se graban en el log los parametros de inicio
				$FEPAGO_PATH_LOG "Inicio de fepago: $gOptModo $gOptBarrido $fDesde $fHasta $montoDesde $montoHasta" "I"				
				return 1
			else
				echo "ERROR en parametros de entrada"
				$FEPAGO_PATH_LOG "Rango de fechas/importes invalido" "E"
			fi
			#se trabaja con rango de Fechas_Importes
		else
			#clear
			echo opcion erronea
		fi
	done
	return 0
}
function mainPrincipal
{
	existeFepago
	existeFeprima
	if [ $GRUPO ]; then
		while [ 1 ]; do
			menuModos
			if [ $? -eq 100 ]; then 
				echo "FIN DE EJECUCION"
				return
			fi
			menuBarrido
			if [ $? -eq 100 ]; then 
				echo "FIN DE EJECUCION"
				return
			fi
			loadVectorFuentes
			recorrerFacturas $FILE_APAGAR "A PAGAR" $gOptBarrido
			mostrarComprometidos
			mostrarDisponibilidades
		done
	else
		exit 1
	fi
}
mainPrincipal
