SET SERVEROUTPUT ON
DECLARE
	--primero creamos la variable del documento xml
	xml_doc DBMS_XMLDOM.DOMDOCUMENT;
	
	-- creamos el root node del que colgaran el resto del documento
	xml_root DBMS_XMLDOM.DOMNODE;
	
	--creamos un elemento y node para el ejemplo
	xml_example_element DBMS_XMLDOM.DOMELEMENT;
	xml_example_node DBMS_XMLDOM.DOMNODE;

	--creamos un nodo y elemento de texto para el ejemplo
	xml_example_text DBMS_XMLDOM.DOMTEXT;
	xml_example_text_node DBMS_XMLDOM.DOMNODE;
	
	--creamos un atrributo y su nodo asociado
	xml_example_attr DBMS_XMLDOM.DOMATTR;

	--creamos un clob para obtener el output de la respuesta
	v_clob_output CLOB:=' ';
BEGIN 
	--incializamos el documento
	xml_doc := DBMS_XMLDOM.NEWDOMDOCUMENT;
	
	--creamos el root node
	xml_root := DBMS_XMLDOM.MAKENODE (xml_doc);
	
	--incluimos la etiqueta xml pidiendole la versión y el encoding
	dbms_xmldom.setVersion(xml_doc, '1.0" encoding="UTF-8');
	
	--asignamos el encoding al documento
	dbms_xmldom.setCharset(xml_doc,'UTF-8');
	
	--creamos un elemento con el nombre example referenciando el documento
	xml_example_element := DBMS_XMLDOM.CREATEELEMENT(xml_doc,'example');
	
	--generamos el node para el elemento recien creado
	xml_example_node := DBMS_XMLDOM.MAKENODE (xml_example_element);

	--creamos el nodo de texto para el contenido del ejemplo y lo rellenamos
	xml_example_text := DBMS_XMLDOM.CREATETEXTNODE (xml_doc, 'text');
	
	--creamos el nodo asociado al nodo de texto
	xml_example_text_node := DBMS_XMLDOM.MAKENODE (xml_example_text);

	--incluimos el nodo del texto en el nodo principal del elemento
	xml_example_text_node := DBMS_XMLDOM.APPENDCHILD(xml_example_node,xml_example_text_node);    
	
	--creamos el atributo de ejemplo
	xml_example_attr:= DBMS_XMLDOM.CREATEATTRIBUTE (xml_doc, 'id');

	--lo rellenamos con contenido.
	DBMS_XMLDOM.SETVALUE(xml_example_attr,'1');
	
	--incluimos el atributo al elemento
	xml_example_attr :=  DBMS_XMLDOM.SETATTRIBUTENODE(xml_example_element,xml_example_attr);

	--incluimos el nodo principal en el root node
	xml_example_node := DBMS_XMLDOM.APPENDCHILD(xml_root,xml_example_node);
	
	--escribimos el xml entero a un clob
	DBMS_XMLDOM.WRITETOCLOB(xml_doc,v_clob_output);
	
	--sacamos por pantalla el contenido del clob
	DBMS_OUTPUT.PUT_LINE(v_clob_output);
	
	--liberamos de la memoria el xml
	DBMS_XMLDOM.freedocument(xml_doc);

	/*
	RESULTADO:
	<?xml version="1.0" encoding="UTF-8"?>
	<example id="1">text</example>

	*/
END;