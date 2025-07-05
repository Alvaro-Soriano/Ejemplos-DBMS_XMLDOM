DECLARE
	--codigo usado para monitorear el XML
	t_inicio	TIMESTAMP  := SYSTIMESTAMP;
	t_fin	TIMESTAMP ;
	n_diff_ms NUMBER;

	--primero creamos el DOMDOCUMENT y el nodo del mismo
	xml_doc DBMS_XMLDOM.DOMDOCUMENT := DBMS_XMLDOM.NEWDOMDOCUMENT;
	xml_root DBMS_XMLDOM.DOMNODE := DBMS_XMLDOM.MAKENODE(xml_doc);

	--Obtenemos los datos del cursor
	CURSOR c_lanzamientos IS
	SELECT * FROM LANZAMIENTOS ORDER BY ID;

	--Creamos un elemento y su nodo asociado para la etiqueta de lanzamientos.
	xml_lanzamientos DBMS_XMLDOM.DOMELEMENT := DBMS_XMLDOM.CREATEELEMENT(xml_doc,'lanzamientos');
	xml_lanzamientos_node DBMS_XMLDOM.DOMNODE := DBMS_XMLDOM.MAKENODE(xml_lanzamientos);

	--Creamos el elemento y el nodo asociado que contendra los totales de las estadisticas
	xml_estadisticas DBMS_XMLDOM.DOMELEMENT := DBMS_XMLDOM.CREATEELEMENT(xml_doc,'estadisticas');
	xml_estadisticas_node DBMS_XMLDOM.DOMNODE := DBMS_XMLDOM.MAKENODE(xml_estadisticas);

	--Creamos los contadores para cada estado del lanzamiento.
	n_exitos NUMBER := 0;
	n_programados NUMBER := 0;
	n_fallos NUMBER := 0;

	--Creamos el elemento lanzamiento y su id asociado
	xml_lanzamiento DBMS_XMLDOM.DOMELEMENT;
	xml_lanzamiento_node DBMS_XMLDOM.DOMNODE;
	xml_id_lanzamiento_attr DBMS_XMLDOM.DOMATTR;

	v_clob CLOB:=' ';


	--Creamos un procedimiento que nos servira de utilidad para simplificar la generación de elementos con texto,
	-- este recibira el nodo padre al que queremos incluir el texto, el nombre de la etiqueta XML y el contenido de la misma
	PROCEDURE PR_GEN_ETIQUETA_TEXTO(
		xml_p_nodo_padre IN OUT DBMS_XMLDOM.DOMNODE,
		v_p_nombre_elemento VARCHAR2,
		v_p_contenido VARCHAR2
	)
	AS
		--Creamos el elemento y su nodo asociado
		xml_elemento DBMS_XMLDOM.DOMELEMENT := DBMS_XMLDOM.CREATEELEMENT(xml_doc,v_p_nombre_elemento);
		xml_elemento_node DBMS_XMLDOM.DOMNODE := DBMS_XMLDOM.MAKENODE(xml_elemento);
		
		--Creamos el elemento de texto y su nodo asociado
		xml_texto DBMS_XMLDOM.DOMTEXT;
		xml_texto_node DBMS_XMLDOM.DOMNODE;
	BEGIN
		--Creamos el nodo del texto y su contenido y su nodo principal
		xml_texto := DBMS_XMLDOM.CREATETEXTNODE (xml_doc, v_p_contenido);
		xml_texto_node := DBMS_XMLDOM.MAKENODE (xml_texto);

		--Incluimos el texto en el elemento y el elemento en su nodo padre
		xml_texto_node := DBMS_XMLDOM.APPENDCHILD(xml_elemento_node,xml_texto_node);
		xml_elemento_node := DBMS_XMLDOM.APPENDCHILD(xml_p_nodo_padre,xml_elemento_node);
	END;


BEGIN
	--Asignamos la versión y el Charset
	DBMS_XMLDOM.SETVERSION(xml_doc, '1.0" encoding="UTF-8');
	DBMS_XMLDOM.SETCHARSET(xml_doc,'UTF-8');

	--Incluimos a la etiqueta lanzamientos el bloque estadisticas.
	xml_estadisticas_node:= DBMS_XMLDOM.APPENDCHILD(xml_lanzamientos_node,xml_estadisticas_node);

	--Recorremos el cursor
	FOR r_lanzamiento IN c_lanzamientos LOOP

		--Inicializamos el elemento lanzamiento y su nodo
		xml_lanzamiento := DBMS_XMLDOM.CREATEELEMENT(xml_doc,'lanzamiento');
		xml_lanzamiento_node := DBMS_XMLDOM.MAKENODE(xml_lanzamiento);

		--Creamos y asignamos el atributo id con el id del lanzamiento a la etiqueta.
		xml_id_lanzamiento_attr := DBMS_XMLDOM.CREATEATTRIBUTE (xml_doc, 'id');
		DBMS_XMLDOM.SETVALUE(xml_id_lanzamiento_attr,r_lanzamiento.ID);
		xml_id_lanzamiento_attr :=  DBMS_XMLDOM.SETATTRIBUTENODE(xml_lanzamiento,xml_id_lanzamiento_attr);


		--Llamamos al procedimiento antes creado con el resto de datos del lanzamiento.
		PR_GEN_ETIQUETA_TEXTO(xml_lanzamiento_node,'NOMBRE_COHETE',r_lanzamiento.NOMBRE_COHETE);
		PR_GEN_ETIQUETA_TEXTO(xml_lanzamiento_node,'EMPRESA',r_lanzamiento.EMPRESA);
		PR_GEN_ETIQUETA_TEXTO(xml_lanzamiento_node,'FECHA_LANZAMIENTO',r_lanzamiento.FECHA_LANZAMIENTO);
		PR_GEN_ETIQUETA_TEXTO(xml_lanzamiento_node,'ESTADO_VUELO',r_lanzamiento.ESTADO_VUELO);

		--Incluimos el lanzamiento al bloque de lanzamientos.
		xml_lanzamiento_node:= DBMS_XMLDOM.APPENDCHILD(xml_lanzamientos_node,xml_lanzamiento_node);

		--Calculamos el total segun el estado del vuelo
		IF r_lanzamiento.ESTADO_VUELO ='EXITO' THEN
			n_exitos := n_exitos +1;
		ELSIF r_lanzamiento.ESTADO_VUELO ='PROGRAMADO' THEN
			n_programados := n_programados +1;
		ELSIF r_lanzamiento.ESTADO_VUELO ='FALLO' THEN
			n_fallos := n_fallos +1;
		END IF;
	END LOOP;

	--Incluimos al bloque de estadisticas los datos de los totales y esta a su vez en el bloque de lanzamientos.
	PR_GEN_ETIQUETA_TEXTO(xml_estadisticas_node,'EXITOS',n_exitos);
	PR_GEN_ETIQUETA_TEXTO(xml_estadisticas_node,'PROGRAMADOS',n_programados);
	PR_GEN_ETIQUETA_TEXTO(xml_estadisticas_node,'FALLOS',n_fallos);
	PR_GEN_ETIQUETA_TEXTO(xml_estadisticas_node,'TOTALES',n_exitos + n_programados + n_fallos);
	xml_lanzamientos_node:= DBMS_XMLDOM.APPENDCHILD(xml_root,xml_lanzamientos_node);

	--escribimos a un clob el contenido
	DBMS_XMLDOM.WRITETOCLOB(xml_doc,v_clob);

	--liberamos el documento de la memoria.
	DBMS_XMLDOM.FREEDOCUMENT(xml_doc);

  t_fin := SYSTIMESTAMP;
  n_diff_ms :=EXTRACT(DAY FROM (t_fin - t_inicio)) * 86400000 + EXTRACT(HOUR FROM (t_fin - t_inicio)) * 3600000 + EXTRACT(MINUTE FROM (t_fin - t_inicio)) * 60000+ EXTRACT(SECOND FROM (t_fin - t_inicio)) * 1000; 
	
	/*
	--Descomentar si se desea Imprimir el XML
	--Codigo necesario para imprimir el CLOB que supera los 32K
	DECLARE
		n_longitud_clob PLS_INTEGER := DBMS_LOB.GETLENGTH(v_clob);
		n_pos PLS_INTEGER := 1;
		n_c_chunk_size CONSTANT PLS_INTEGER := 32767;
		v_chunk VARCHAR2(32767);
	BEGIN
		n_longitud_clob  := DBMS_LOB.GETLENGTH(v_clob);
		WHILE n_pos <= n_longitud_clob LOOP
			v_chunk := DBMS_LOB.SUBSTR(v_clob,LEAST(n_c_chunk_size, n_longitud_clob - n_pos + 1),n_pos);
		DBMS_OUTPUT.PUT_LINE(v_chunk);
			n_pos := n_pos + n_c_chunk_size;
		END LOOP;
	END;
	*/


	--Retornamos el resultado del rendimiento de la generación.
	DBMS_OUTPUT.PUT_LINE('Rendimiento de la generación del XML (Milisegundos): ' || n_diff_ms|| ' tamaño del documento (Kb): '||ROUND(DBMS_LOB.GETLENGTH(v_clob) / 1024, 3)||' '||
	'Numero de líneas: '||(DBMS_LOB.GETLENGTH(v_clob)- DBMS_LOB.GETLENGTH(REPLACE(v_clob, CHR(10), ''))) 
	);
	
	--liberamos el clob de la memoria
	DBMS_LOB.FREETEMPORARY(v_clob);

--En caso de dar error libera el XML y el CLOB
EXCEPTION
	WHEN OTHERS THEN
		BEGIN
			DBMS_XMLDOM.FREEDOCUMENT(xml_doc);
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;

		BEGIN
			DBMS_LOB.FREETEMPORARY(v_clob);
		EXCEPTION
			WHEN OTHERS THEN
				NULL;
		END;
END;