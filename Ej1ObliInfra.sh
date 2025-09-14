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
		if [ $1 = $userinfile ]; 
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
    local valor=""
    local mensaje="$1"

    while true; do
			echo "$mensaje"
        read valor
        valor=$(echo "$valor" | xargs)  # quitar espacios al inicio y fin
        if [ -n "$valor" ]; then
            echo "$valor"
            return
        else
            echo "No puede estar vacío. Intente nuevamente."
        fi
    done
}

#funcion para verificar si el valor numerico que ingresa el usuario es entro o no, tambien verifica si es positivo
validarEntero () {
    local valor=""
    local mensaje="$1"

    while true; do
        echo "$mensaje"
        read valor
        valor=$(echo "$valor" | xargs)
        if [[ "$valor" =~ ^[0-9]+$ ]]; then
            echo "$valor"
            return
        else
            echo "Debe ingresar un número entero positivo."
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
	#primero que nada un array para los posibles productos que quiera comprar el usuario
    compras=() 


    while true; do
        echo "--Lista de productos--"
        # Se muestra unicamente en la lista de productos, los datos necesarios, el número, tipo, modelo y precio
        awk -F"|" '{printf "%2d) %s - %s - $%s\n", NR, $2, $3, $6}' "$inventario"

        # Selección de producto
        leerNoVacio "Ingrese el número del producto: "
        numProd=$respuesta

        # se obtiene la línea del producto elegido
        linea=$(sed -n "${numProd}p" "$inventario")
		# en caso de que no haya un producto con el valor ingresado, se le pide nuevamente
        if [ -z "$linea" ]; then
            echo "Producto inválido."
            continue
        fi

		#se separan los datos de la linea que estaban divididos por |
        IFS="|" read -r codigo tipo modelo descripcion stock precio <<< "$linea"

        
        while true; do
			#se chequea si ingresa valor vacio
            verificarTextoNoVacio "Ingrese la cantidad a comprar: "
            cantidadCompra=$respuesta
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
        sed -i "${numProd}s/.*/$nuevaLinea/" "$inventario"

        echo "Agregado: $cantidadCompra x $modelo (\$${subtotal})"

        # preguntar si quiere seguir comprando
        read -p "¿Desea comprar otro producto? (s/n): " seguir
        if [[ "$seguir" != "s" ]]; then
            break
        fi
    done

    echo "==== Resumen de compra ===="
    totalDeCompra=0
	#se le muestra al usuario todo lo que compro y se va sumando a un total y al final se lo muestra 
    for compra in "${compras[@]}"; do
        IFS="|" read -r codigo tipo modelo descripcion cantidad precio subtotal <<< "$compra"
        echo "- [$codigo] $tipo $modelo | Cantidad: $cantidad | Precio: \$${precio} | Subtotal: \$${subtotal}"
        totalGeneral=$((totalGeneral + subtotal))
    done
    echo "TOTAL A PAGAR: \$${totalDeCompra}"
}

