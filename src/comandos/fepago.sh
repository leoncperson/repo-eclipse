#!/bin/bash
MSG="./glog"                 #Nombre del script que imprime mensajes en archivo de log
#constantes
A_PAGAR="A PAGAR"
FILE_APAGAR=$PWD"/../facturas/apagar.txt"
FILE_PRESU=$PWD"/../pp/presu.txt"
FILE_APAGAR_VERSION=$PWD"/../facturas/old/apagar."
FILE_APAGAR_TEMP=$PWD"/../facturas/old/apagar.tmp"
FILE_PRESU_VERSION=$PWD"/../pp/old/presu."
FILE_PRESU_TEMP=$PWD"/../pp/old/presu.tmp"
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
gNroVersionPresu=
gNroVersionAPagar=

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
		$MSG $PWD/log/"fepago" "Se ha encontrado una instancia previa del programa fepago" "E"
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
		$MSG $PWD/log/"fepago" "Se ha encontrado una instancia previa del programa feprima" "E"
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
function OLD_checkParametros
{
	#se graba en el log
	$MSG $PWD/log/"fepago" "Inicio de fepago: $1 $2" "I"
	if [ -z $1 ] ; then
		$MSG $PWD/log/"fepago" "Error en cantidad de argumentos" "E"
		exit 0
	fi
	if [ -z $2 ] ; then
		$MSG $PWD/log/"fepago" "Error en cantidad de argumentos" "E"
		exit 0
	fi
	if [ -z $3 ] ; then
		$MSG $PWD/log/"fepago" "Error en cantidad de argumentos" "E"
		exit 0
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
# $1 nombre del archivo
# $2 nro de fuente a buscar
function getMontoxFuente
{
#linea de presu.txt
#fuente;montoDisponible;fechaUltModif;userUltModif
	fuente=$2
	while read line
	do 
		fuenteLine=`echo "$line" | sed "s/^\([0-9]\{2\}\);.*/\1/"`	   
		echo FUENTE es $fuenteLine
		montoDispo=`echo "$line" | sed "s/^\([0-9]\{2\}\);\([0-9]*\.[0-9]\{2\}\);.*/\2/"`	   
		echo MONTO es $montoDispo
		if [ "$fuente" -eq "$fuenteLine" ]
		then
			gMontoFuente=$montoDispo
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
	nroFuente=$?
	getMontoxFuente $FILE_PRESU $nroFuente $montoFte
	montoFte=$?
	if [ `echo $montoPag>$montoFte | bc` ]; then
		return 0
	else
		return 1
	fi	
}
# $1 valor a restar de la disponibilidad
function updateDispo
{
	montoPag=$1
	getFuenteByRango $montoPag
	nroFte=$?
	getMontoxFuente $FILE_PRESU $nroFte
	echo BUG-010
	montoFte=$gMontoFuente
	echo $montoPag $montoFte
	if [ `echo "$montoPag > $montoFte" | bc -l` -eq 1 ]; then
		return 0
	else
		#sed -e 's/11;\([0-9]*.[0-9]\{2\}\)/11;33/g' test.txt 
		diferMonto=`echo $montoFte-$montoPag | bc`
		echo $diferMonto DIFER
		sed $FILE_PRESU -e "s/$nroFte;\([0-9]*.[0-9]\{2\}\);/$nroFte;$diferMonto;/g" > $FILE_PRESU_TEMP
		cat $FILE_PRESU_TEMP > $FILE_PRESU
		rm -f $FILE_PRESU_TEMP
		return 1
	fi	
}
# recorre el archivo de facturas
# $1 nombre de archivo
# $2 estado de busqueda
# $3 opt del mennu
function recorrerFacturas
{
	numLine=0	
	estado=$2
	opt=$3
	while read line
	do
		procFileFacturaAPagar $estado $numLine $line
		# 1ero se filtra por estado "A PAGAR"	
		if [ $? -eq 1 ]; then
			echo "checkCondicion"
			checkCondicion $opt
			# 2do se filtra por la condicion de barrido
			if [ $? -eq 1 ]; then
				# 3ero se filtra por la disponibilidad
				checkDispo $gMontoPag
				if [ $? -eq 1 ]; then
					echo $FILE_APAGAR_TEMP
					echo $line >> $FILE_APAGAR_TEMP
					echo "OK"
					updateDispo $gMontoPag
					return 1
				fi
			fi
		fi
	done < $1
	return 0
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
	#line=$3
	numLine=$((numLine+1))
# 	echo $numLine
	codigoCAE=`echo "$line" | sed "s/^\([0-9]\{14\}\);.*/\1/"`	   
# 	echo CAE es $codigoCAE
	fechaVenc=`echo "$line" | sed "s/^\([0-9]\{14\}\);\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\);.*/\2/"`	   
# 	echo FECHAVENC es $fechaVenc
	montoPag=`echo "$line" | sed "s/^\([0-9]\{14\}\);\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\);\([0-9]*\.[0-9]\{2\}\).*/\3/"`   
# 	echo MONTOPAG es $montoPag
#	estadoFac=`echo "$line" | sed "s/^\([0-9]\{14\}\);\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\);\([0-9]*\.[0-9]\{2\}\);\([A-Z ]\)/\4/"`
	estadoFac=`echo "$line" | sed "s/^[^;]*;[^;]*;[^;]*;\([^;]*\).*$/\1/"`
# 	estadoFac=`echo "$line" | cut -d";" -f4` `
#si falla aca invocar antes a
#perl -i -p -e 's/\r\n/\n/' ../facturas/apagar.txt
# para sacar los fin de linea de windows
	if [ `echo "$numLine>$gNumLineFac" | bc` ]; then
		if [ "$estadoFac" = "A PAGAR" ]; then
			echo IGUAL
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
	echo "1000.00 > $valor" | bc -l
	if [ `echo "1000.00 > $valor" | bc -l`-eq1 ]; then
	echo busca rango para $valor
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
	local retcode=$?
	echo RET es "$retcode"

	if [ $? -ne 0 ]
	then 
		$MSG $PWD/log/"fepago" "Faltan inicializar variables de ambiente" "E"
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
	line=$1
	year=`echo $line | cut -d"-" -f1`
	if test -z $year ; then
		return 0
	else
		year=`echo "$year" | grep '19[0-9][0-9]\|20[0-3][0-7]\|2008\|2009'`
		if test -z $year ; then
			return 0
		fi
	fi
	month=`echo $line | cut -d"-" -f2`
	if test -z $month ; then
		return 0
	else
		month=`echo "$month" | grep '1[0-2]\|0[1-9]'`
		if test -z $month ; then
			return 0
		fi
	fi
	day=`echo $line | cut -d"-" -f3`
	if test -z $day ; then
		return 0
	else
		day=`echo "$day" | grep '[0-2][0-9]\|30\|31'`
		if test -z $day ; then
			return 0
		fi		
	fi
	return 1
}
#recibe un argumento $1 que contiene el monto a validar
#retorna 1 si es valido
#retorna 0 si es invalido
function validMonto
{
	line=$1
	montoTemp=`echo "$line" | grep '^\([0-9]*\.[0-9][0-9]\)$'`
	
	if test -z $montoTemp
	then
		return 0
	fi
	return 1
}
#obtiene la version del archivo
#actualiza el nro de version
#si no existe lo crea
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
	cat $archivo
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
			fechaDesde=$1
			fechaHasta=$2		
			fechaDesde=`date -d $fechaDesde +%Y%m%d`
			fechaHasta=`date -d $fechaHasta +%Y%m%d`
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
			if [ `echo "$montoDesde>$montoHasta" | bc -l`-eq1 ]; then
				return 0
			else
				gMontoDesde=$montoDesde
				gMontoHasta=$montoHasta
				return 1
			fi			
		fi
	else
		return 0
	fi	
	
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
	echo BUG-000
	if [ "$opt" = "Fechas" ]; then
		#recibe fechaDesde,fechaHasta valorFecha
		checkCondicionFechas $gFechaDesde $gFechaHasta $gFechaVenc
		return $?
	fi
echo $opt BUG-001	
	if [ "$opt" = "Importes" ]; then
		#recibe montoDesde,montoHasta valorMonto
		checkCondicionMontos $gMontoDesde $gMontoHasta $gMontoPag
		return $?
	fi
echo BUG-002
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
echo BUG-003	
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
	valorFecha=$3
	fechaDesde=`date -d $fechaDesde +%Y%m%d`
	fechaHasta=`date -d $fechaHasta +%Y%m%d`
	valorFecha=`date -d $valorFecha +%Y%m%d`
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
	if [ `echo $montoDesde>$valorMonto | bc`]; then
		return 0
	else
		if [ `echo $valorMonto>$montoHasta | bc`]; then
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
			echo Simulacion
			gOptModo=1
			return 1
		elif [ "$opt" = "Actualizacion" ]; then
			echo Actualizacion
			gOptModo=2
			return 2
		elif [ "$opt" = "Salir" ]; then
			echo Salir
			gOptModo=100
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
				gFechaDesde=$fDesde
				gFechaHasta=$fHasta
				gOptBarrido=$opt
				return 1
			else
				echo "ERROR en parametros de entrada"
				$MSG $PWD/log/"fepago" "Rango de fechas invalida" "E"
			fi
			#se trabaja con rango de fechas
		elif [ "$opt" = "Importes" ]; then
			echo "Importes"
			echo Ingrese [montoDesde] [montoHasta]
			echo formato XXX X.XX
			read montoDesde
			read montoHasta
			validRangoMontos $montoDesde $montoHasta
			if [ $? -eq 1 ]; then
				gMontoDesde=$montoDesde
				gMontoHasta=$montoHasta
				gOptBarrido=$opt
				return 1
			else
				echo "ERROR en parametros de entrada"
				$MSG $PWD/log/"fepago" "Rango de importes invalido" "E"
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
				return 1
			else
				echo "ERROR en parametros de entrada"
				$MSG $PWD/log/"fepago" "Rango de fechas/importes invalido" "E"
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
	#se graba en el log
	$MSG $PWD/log/"fepago" "Inicio de fepago:" "I"
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
	gNroVersionPresu=
	#se borra el temporal por si estaba
	rm -f $FILE_APAGAR_TEMP
	echo LIN685
	recorrerFacturas $FILE_APAGAR "A PAGAR" $gOptBarrido
}
#recorrerArch_presu
#mainCheck
#existeFepago
#existeFeprima

mainPrincipal
