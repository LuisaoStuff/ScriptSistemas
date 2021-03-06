#!/bin/bash

CancelarPulsado() {
	if [ $? -eq 1 ]; then
		dialog --infobox "No se creará el enlace simbólico" 0 0
		VolverMenu		
		sleep 1
	fi
}

ImprimirMenu() {
	typeset -i Opcion
	Indice=$(($1+1))
	Opcion=$(dialog --cancel-label "Salir" --menu "Aun no has avanzado en la instalación:" 0 0 0 \
		1 "Seleccionar/Crear/Añadir diccionario" \
		2 "Modificar el intervalo de tiempo" \
		3 "Cambiar paquete de ejecución" \
		4 "Cambiar fecha de inicio" \
		5 "Gestion de usuarios" 3>&1 1>&2 2>&3)

	while [ $Opcion -gt $Indice ]; do
		dialog --msgbox "Aún no has configurado los parámetros anteriores" 0 0
		Opcion=$(dialog --cancel-label "Salir" --menu "Aun no has avanzado en la instalación:" 0 0 0 \
		1 "Seleccionar/Crear/Añadir diccionario" \
		2 "Modificar el intervalo de tiempo" \
		3 "Cambiar paquete de ejecución" \
		4 "Cambiar fecha de inicio" \
		5 "Gestion de usuarios" 3>&1 1>&2 2>&3)
	done
	return $Opcion
}


ComprobarSalida() {
	typeset -i salida
	typeset -i contador
	typeset -a Menu
	salida=$1
	contador=$2
	echo $salida
	Menu=("Seleccionar/Crear/Añadir diccionario" "Modificar el intervalo de tiempo" "Cambiar paquete de ejecución" "Cambiar fecha de inicio" "Lista de usuarios")
	menubox=""
	if [ $salida -eq 255 ]; then
		typeset -i Opcion
		for i in {1..$contador}; do
			menubox="$menubox $i ${Menu[$i]} "
		done
		Opcion=$(dialog --menu "Elige una de las opciones:" 0 0 0 $menubox 3>&1 1>&2 2>&3)
		return $Opcion
	else
		return $contador
	fi	
}

ComprobarInstalado() {
	paquete=$1
	instalado=$2
	set `whereis $paquete`
	if [ $# -eq 1 ]; then
		apt-get install -y $paquete
		if [ $? -eq 0 ];then
			return 0
		else
			return 1
		fi
	fi
	return 0
}

ComprobarDialogInstalado() {
	if [ "$1" = "dialog no instalado" ]; then
		echo "No se pudo instalar dialog, prueba a instalarlo manualmente"
		sleep 2
		clear
		clear && exit
	fi
}

if [ "$USER" != "root" ]; then
	echo "Debes tener permisos de superusuario"
	sleep 1.5
	clear
	clear && exit
fi

ruta=`dirname $0`

SCRT=$(readlink -f $0)

echo "Este es el script de instalación de Check-Pass"

echo "Comprobando el estado de los paquetes necesarios..."

typeset -a Lista
typeset -i Instalado
typeset -a Paquetes

Paquetes=("crontab" "hydra" "medusa" "ncrack" "dialog")
typeset -i indicador

for i in {0..4}; do
	set `whereis ${Paquetes[$i]}`
	ComprobarInstalado ${Paquetes[$i]} $#
	indicador=$(ComprobarInstalado ${Paquetes[$i]} $#)
	if [ $indicador -eq 0 ]; then
		Lista[$i]="${Paquetes[$i]}	instalado"
	else
		Lista[$i]="${Paquetes[$i]}	no instalado"
	fi
done

ComprobarDialogInstalado Lista[4]

echo "Se han instalado los siguientes paquetes: " > $ruta/install-temp.txt

for i in {0..4}; do
	echo "  -${Lista[$i]}" >> $ruta/install-temp.txt
done

dialog --textbox $ruta/install-temp.txt 0 0
rm $ruta/install-temp.txt

typeset -i SALIDA
SALIDA=0

typeset -a Config
Config=($ruta/Config/Diccionarios-Config.sh $ruta/Fechas/Intervalo-Config.sh $ruta/Config/CommandMenu.sh $ruta/Usuarios/Gestion-Usuarios.sh $ruta/Fechas/Fechas-Config.sh)

typeset -i i
typeset -i Indice
typeset -i salida
i=0
Indicador=0
while [ $i -le 4 ]; do
	if [ $i -eq 0 ];then	
		${Config[$i]} "--nocancel" "(Pulsa 'no' para continuar la instalacion)"
	else
		${Config[$i]} "--nocancel"
	fi
	salida=$(cat $ruta/salida.txt)
	if [ $salida -eq 255 ]; then

		ImprimirMenu $i
		Opcion=$?
		if [ $Opcion -eq 255 -o $Opcion -eq 0 ]; then
			clear
			exit
		fi
		i=$(($Opcion-1))
	elif [ $salida -eq 0 ]; then
		i=$(($i+1))
	fi	
done
rm -rf $ruta/salida.txt
dialog --msgbox "Instalación completada" 0 0
dialog --yesno "¿Deseas crear un enlace simbólico al script de configuración?" 0 0
if [ $? -eq 0 ]; then

	Directorio=$(dialog --inputbox "Introduce un directorio válido para ubicar el enlace:" 0 0 3>&1 1>&2 2>&3)
	CancelarPulsado
	cd $Directorio
	val=$(echo $?)
	while [ $val -eq 1 ]; do
		dialog --msgbox "Debes introducir un directorio válido." 0 0		
		Directorio=$(dialog --inputbox "Introduce un directorio válido para ubicar el enlace:" 0 0 3>&1 1>&2 2>&3)
		CancelarPulsado
		cd $Directorio
		val=$(echo $?)
	done
	
	Final=$(echo "$Directorio" | rev)
	Final=$(echo "${Final:0:${#Final}-${#Final}+1}")	# Compruebo que tenga barra al final, si la tiene se la quito para evitar problemas
	if [ "$Final" = "/" ]; then				# Al ejecutar el comando ln -s
		Directorio=$(echo "${Directorio:0:${#Directorio}-1}")
	fi

	Nombre=$(dialog --inputbox "Introduce el nombre del enlace:" 0 0 3>&1 1>&2 2>&3)
	CancelarPulsado
	ln -s $SCRT $Directorio/$Nombre
fi
clear
