#!/bin/bash

loggedUser=""
inventario="inventario.txt"
file="usuariosycontrasenas.txt"

chequearUsuario () {
	existeUser=0
	#recorrer un archivo, mientra que tenga lineas el archivo el while continua
	while IFS= read -r line; do
		#el -d te lo divide si aparece | y -f selecciona la columna
		userinfile=$(echo $line | cut -d "|" -f 1)
		#$1 es el rpimer parametro de la funcion
		if [ "$1" = "$userinfile" ]; 
		then
			existeUser=1
		
		fi
		
	#mientras que queden lineas en file lo repite	
	done < "$file"
	echo $existeUser
}


altausuario () {
	echo "Ingrese nombre usuario"
	read username
	#se fija llamando a la funcion si el usuario existe
	result=$(chequearUsuario $username)
	while [ "$result" != "0" ]; do
		echo "Usuario existente re Ingrese nombre usuario"
		read username
		result=$(chequearUsuario $username)
	done 
	echo "Ingrese password"
	read password
	#hay que chequear si la contraseña es vacia, el xargs elimina espacios al principio y fin por si la persona pone contraseña un espacio vacio
	password=$(echo "$password" | xargs)
	#miesntras que este vacia se la va a seguir pidiendo
    while [ -z "$password" ]; do
        echo "La contraseña no puede estar vacía. Ingrese nuevamente:"
        read password
        password=$(echo "$password" | xargs)
    done
	#si se pone solo un mayor te borra lo que estaba y te deja solo lo nuevo, si pones dos mayores te concatena con lo que estaba al final
	echo $username"|"$password  >> usuariosycontrasenas.txt
	echo  "Usuario creado"

}

cambiarPassword () {
	#se le pide el nombre del usuario para ver si existe en la lista de usuarios
    echo "Ingrese nombre de usuario"
    read username

    # se verifica si existe
    result=$(chequearUsuario $username)
    if [ "$result" = "0" ]; then
        echo "Usuario no existe"
        return
    fi

	#se le pide que ingrese su contraseña actual
    echo "Ingrese contraseña actual"
    read -s oldpass

    # Buscar la línea con ese usuario en el archivo
    userline=$(grep "^$username|" usuariosycontrasenas.txt)

    # Obtener la contraseña que esta guardada
    savedpass=$(echo "$userline" | cut -d "|" -f2)
	
	#por seguridad se compara si la contraseña que puso es igual a la contraseña que esta guardada
    if [ "$oldpass" != "$savedpass" ]; then
        echo "Contraseña incorrecta"
        return
    fi

	#en caso de estar todo correcto le pide que ingrese la contraseña para realizar el cambio
    echo "Ingrese nueva contraseña"
    read -s newpass
    newpass=$(echo "$newpass" | xargs)

    while [ -z "$newpass" ]; do
        echo "La contraseña no puede estar vacía. Ingrese nuevamente:"
        read -s newpass
        newpass=$(echo "$newpass" | xargs)
    done

    # se usa sed para reemplazar la contraseña en el archivo, busca en el archivo el usuario que se llame igual y cambia la pass
    sed -i "s/^$username|.*/$username|$newpass/" usuariosycontrasenas.txt

    echo "Contraseña actualizada con éxito"
}

login () {
	#se le pide el nombre de usuario
    echo "Ingrese nombre de usuario"
    read username

    # verificar si existe
    result=$(chequearUsuario $username)
    if [ "$result" = "0" ]; then
        echo "Usuario no existe"
        return 1
    fi
	
    echo "Ingrese contraseña"
    read -s password

    # busca la línea y obtener pass para luego verificar si es correcto
    userline=$(grep "^$username|" usuariosycontrasenas.txt)
    savedpass=$(echo "$userline" | cut -d "|" -f2)

	# se verifica si esta correcta la pass del usuario
    if [ "$password" = "$savedpass" ]; then
        loggedUser=$username
        echo "Bienvenido, $username!"
        return 0
    else
        echo "Contraseña incorrecta"
        return 1
    fi
}

# metodo para que a la hora de intentar utilizar una funcion se lanze el mensaje de que no hay usuarios logueados
restringido () {
    if [ -z "$loggedUser" ]; then
        echo "Debe iniciar sesión para usar esta opción."
        return
    fi
}


logout () {
    if [ -z "$loggedUser" ]; then
        echo "Ningún usuario está logueado."
    else
        echo "Usuario $loggedUser deslogueado."
        loggedUser=""
    fi
}

#funcion auxiliar para verificar que el texto que pasa el usuario no esta vacio
verificarTextoNoVacio () {
    local mensaje="$1"
	local valor=""

    while true; do
		#echo "$mensaje" >&2
        read -r -p "$mensaje " valor < /dev/tty
        valor=$(echo "$valor" | xargs)  # quitar espacios al inicio y fin
        if [ -n "$valor" ]; then
            #echo "$valor"
			printf "%s" "$valor"
            return
        else
            echo "No puede estar vacío. Intente nuevamente." >&2
        fi
    done
}

#funcion para verificar si el valor numerico que ingresa el usuario es entro o no, tambien verifica si es positivo
validarEntero () {
    local valor=""
    local mensaje="$1"

    while true; do
        #echo "$mensaje"
        #read valor
		read -r -p "$mensaje " valor < /dev/tty
        valor=$(echo "$valor" | xargs)
        if [[ "$valor" =~ ^[0-9]+$ ]]; then
            #echo "$valor"
			printf "%s" "$valor"
            return
        else
            echo "Debe ingresar un número entero positivo.">&2
        fi
    done
}

ingresarProducto () {
    if [ -z "$loggedUser" ]; then
        echo "Debe iniciar sesión para usar esta opción."
        return
    fi

	
	# hay que validar el tipo que ingresa el usuario para verificar si es uno de los que hay en la lista , para esto nos creamos uin array con todos los tipos posibles
    tiposValidos=("Base" "Layer" "Shade" "Dry" "Contrast" "Technical" "Texture" "Mediums")
	
	# un bucle hasta que se llegue a un producto valido para ingreasar
    while true; do
		#se le manda a la funcion auxiliar para verificar su nio esta vacio loque ingreso
        tipo=$(verificarTextoNoVacio "Ingrese tipo de pintura (Base, Layer, Shade, Dry, Contrast, Technical, Texture, Mediums):")
		#echo "Ingrese tipo de pintura (Base, Layer, Shade, Dry, Contrast, Technical, Texture, Mediums):"
		#tipo=$(verificarTextoNoVacio)
		#variable para que arranca en 0, en el caso de encontrar en la lista algun tipo que sea igual al que ingresa el usuario, para a valer 1
        esTipoValido=0
		# se va comparando uno a uno el ingresado por el usuario con los del aray de validos
        for t in "${tiposValidos[@]}"; do
            if [ "$tipo" = "$t" ]; then
                esTipoValido=1
				#en caso de ser valido deja de recorrer el array
                break
            fi
        done
        if [ $esTipoValido -eq 1 ]; then
            break
        else
			#si no es valido le pide que ingrese de nuevo
            echo "Tipo inválido. Debe ser uno de: ${tiposValidos[*]}"
        fi
    done

	#el codigo son las tres primeras letras del tipo en mayus, por lo tanto se corta el tipo y se pasan a mayuscula
    codigo=$(echo "$tipo" | cut -c1-3 | tr '[:lower:]' '[:upper:]')

	#se validan los datos que ingresan los usuarios con las funciones auxiliares creadas anteriormente
    modelo=$(verificarTextoNoVacio "Ingrese modelo:")
    descripcion=$(verificarTextoNoVacio "Ingrese descripción:")
    cantidad=$(validarEntero "Ingrese cantidad:")
    precio=$(validarEntero "Ingrese precio unitario:")
	
	#se guarda el nuevo producto en el archivo
    echo "$codigo|$tipo|$modelo|$descripcion|$cantidad|$precio" >> "$inventario"
	
	#se muestra el resultado en pantalla
	echo "$codigo - $tipo - $modelo - $descripcion - $cantidad - \$ $precio"
    echo "Producto ingresado correctamente"
}


venderProducto() {

	if [ ! -s "$inventario" ]; then
        echo "No hay productos disponibles."
        return
    fi
	#primero que nada un array para los posibles productos que quiera comprar el usuario
    compras=() 


    while true; do
		
		stock_disponible=$(awk -F"|" '{if ($5+0 > 0) c++} END {print c}' "$inventario")

		if [ -z "$stock_disponible" ] || [ "$stock_disponible" -eq 0 ]; then
			echo "No quedan productos con stock disponible."
			break
		fi
		
        echo "--Lista de productos--"
        # Se muestra unicamente en la lista de productos, los datos necesarios, el número, tipo, modelo y precio
        awk -F"|" '{printf "%2d) %s - %s - $%s\n", NR, $2, $3, $6}' "$inventario"

        # Selección de producto
        numProd=$(verificarTextoNoVacio "Ingrese el número del producto:")

        # se obtiene la línea del producto elegido
        linea=$(sed -n "${numProd}p" "$inventario")
		# en caso de que no haya un producto con el valor ingresado, se le pide nuevamente
        if [ -z "$linea" ]; then
            echo "Producto inválido."
            continue
        fi

		#se separan los datos de la linea que estaban divididos por |
        IFS="|" read -r codigo tipo modelo descripcion stock precio <<< "$linea"

		if [ "$stock" -le 0 ]; then
            echo "Sin stock disponible para este producto."
            sleep 1
            continue
        fi
        
        while true; do
			#se chequea si ingresa valor vacio
            #verificarTextoNoVacio "Ingrese la cantidad a comprar: "
            #cantidadCompra=$respuesta
			cantidadCompra=$(verificarTextoNoVacio "Ingrese la cantidad a comprar:")

			#se hacen chequeos de si el valor eso valido, si es el valor es menor que 0 y si es menor o no al stock que hay del producto
            if ! [[ "$cantidadCompra" =~ ^[0-9]+$ ]]; then
                echo "Debe ser un número válido."
                continue
            fi
            if [ "$cantidadCompra" -le 0 ]; then
                echo "La cantidad debe ser mayor que 0."
            elif [ "$cantidadCompra" -gt "$stock" ]; then
                echo "Stock insuficiente (máximo $stock)."
            else
                break
            fi
        done

        # Se guarda la compra en el array de compras
        subtotal=$((cantidadCompra * precio))
        compras+=("$codigo|$tipo|$modelo|$descripcion|$cantidadCompra|$precio|$subtotal")

        # se actualiza el stock en el inventario
        nuevoStock=$((stock - cantidadCompra))
        nuevaLinea="$codigo|$tipo|$modelo|$descripcion|$nuevoStock|$precio"
        #sed -i "${numProd}s/.*/$nuevaLinea/" "$inventario"
		
		awk -v n="$numProd" -v repl="$nuevaLinea" 'NR==n{$0=repl} {print}' "$inventario" > "$inventario.tmp" && mv "$inventario.tmp" "$inventario"
		sync
		
        echo "Agregado: $cantidadCompra x $modelo (\$${subtotal})"

        # preguntar si quiere seguir comprando
        read -p "¿Desea comprar otro producto? (s/n): " seguir
        if [[ "$seguir" != "s" ]]; then
            break
        fi
    done
	if [ "${#compras[@]}" -gt 0 ]; then
		echo "==== Resumen de compra ===="
		totalDeCompra=0
		#se le muestra al usuario todo lo que compro y se va sumando a un total y al final se lo muestra 
		for compra in "${compras[@]}"; do
			IFS="|" read -r codigo tipo modelo descripcion cantidad precio subtotal <<< "$compra"
			echo "- [$codigo] $tipo $modelo | Cantidad: $cantidad | Precio: \$${precio} | Subtotal: \$${subtotal}"
			totalDeCompra=$((totalDeCompra + subtotal))
		done
		echo "TOTAL A PAGAR: \$${totalDeCompra}"
	fi
}


filtrarProductos(){
	if [ -z "$loggedUser" ]; then
        echo "Debe iniciar sesión para usar esta opción."
        return
    fi
	
	#con esto determinamos si existe el archivo y si no esta vacio(el -s determina si existe y si tiene un tamaño mayor a 0 bytes)
	if [ ! -s "$inventario" ]; then
        echo "No hay productos cargados."
        return
    fi
		
	#se le pide el filtro al usuario
	echo "Filtrar por TIPO (Base, Layer, Shade, Dry, Contrast, Technical, Texture, Mediums). Si no ingresa nada se retornan todos:"
    read -r filtro

	#este if es para el caso de que venga vacio el filtro, deberia de mostrar todos los productos
	if [ -z "$filtro" ]; then
        # divide cada linea del inventario por los | para que a cada seccion del producto se la guarde en lugares separados
        awk -F"|" '
        BEGIN {
            printf "%-3s %-10s %-22s %-38s %6s %8s\n","N°","Tipo","Modelo","Descripción","Stock","Precio"; 
            print  "-----------------------------------------------------------------------------------------------"
        }
        { printf "%-3d %-10s %-22s %-38s %6d %8d\n", NR, $2, $3, $4, $5, $6 }
        ' "$inventario"
		#el primer printf se ejecuta una sola vez para poner la cabezera especifica para que el suaurio entienda que es cada cosa del producto
		#el segundo printf se ejecuta para cada linea del archivo hasta que no queden mas productos 
    else
		#este else es cuando se le madna un filtro especifico para los productos
		awk -F"|" -v f="$filtro" '
        BEGIN {
            printf "%-3s %-10s %-22s %-38s %6s %8s\n","N°","Tipo","Modelo","Descripción","Stock","Precio";
            print  "-----------------------------------------------------------------------------------------------"
        }
        tolower($2) == tolower(f) {
            hay=1
            printf "%-3d %-10s %-22s %-38s %6d %8d\n", NR, $2, $3, $4, $5, $6
        }
        END {
            if (!hay) print "No se encontraron productos de ese tipo."
        }
        ' "$inventario"
		#el primer print es lo mismo que en el if 
		#la condicion de tolower permite que el bloque solo se ejecute cuando el tipo de producto($2) coincida con el valor del filtro sin importar mayus/minus.
		#agregamos una variable llamada hay que como es un awk la inicializa en 0 y en caso de encontrar un producto con ese tipo la va a pasar a 1, esta misma la usamos al final para determinar si hay o no productos con ese tipo
    fi
	
}

crearReporteDePinturas(){
	if [ -z "$loggedUser" ]; then
        echo "Debe iniciar sesión para usar esta opción."
        return
    fi
	#se crea la carpeta datos en caso de que no exista, esto es en caso de querer correr el ejecutable en otra carpeta
	mkdir -p "Datos"
	#nombre que tiene el archvio en donde se guardan los datos
	reporte="Datos/datos.CSV"
	
	#primera linea del archivo que muestra los nombres de las columnas del archivo
	echo "codigo,tipo,modelo,descripcion,cantidad,precio" > "$reporte"
	 
	#en caso de que no haya ningun producto, se genera el archivo de datos solo con el encabezado
	if [ ! -s "$inventario" ]; then
        echo "Inventario vacío. Se generó el archivo con solo el encabezado."
        return
    fi
	
	#se divide cada linea del archivo por | y se van agregando hasta que no queden mas productos en el inventario
	while IFS="|" read -r codigo tipo modelo descripcion cantidad precio; do
        echo "$codigo,$tipo,$modelo,$descripcion,$cantidad,$precio" >> "$reporte"
    done < "$inventario"
	
	#mensaje final para que el usuario sepa que se guardo el reporte
	echo "Reporte creado correctamente en: $reporte"
}






menuPrincipal () {

while :
do
#Menu
clear
	#Menu 
	echo " MENU Principal Ejercicio 1 "
	echo "1. Usuario"
	echo "2. Ingresar Producto"
	echo "3. Vender Producto"
	echo "4. Filtro de productos"
	echo "5. Crear reporte de pinturas"
	echo "6. Salir"


	#Escoger menu
	echo -n "Escoger opcion: "
	read opcion

	#Seleccion de menu, dentro se encuentran las funciones utilizadas


	case $opcion in
    1)
        echo "a. Crear Usuario"
        echo "b. Cambiar contraseña"
        echo "c. Login"
        echo "d. Logout"

        echo -n "Escoger opción: "
        read opcionUser

        case $opcionUser in
            a)
                altausuario
                ;;
            b)
                cambiarPassword
                ;;
            c)
                login
                ;;
            d)
                logout
                ;;
            *)
                echo "Opción inválida"
                ;;
        esac  
        read foo
        ;;    
    2)
		echo "Ingreso de nuevo producto"
		ingresarProducto
        read foo
        ;;
    3)
        venderProducto
        read foo
        ;;
    4)
        filtrarProductos
        read foo
        ;;
    5)
        crearReporteDePinturas
        read foo
        ;;
    6)
        exit 0
        ;;
    *)
        echo "Opción inválida..."
        sleep 1
        ;;
	esac
done

}

menuPrincipal