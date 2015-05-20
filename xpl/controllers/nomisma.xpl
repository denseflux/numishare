<?xml version="1.0" encoding="UTF-8"?>
<!--
	Copyright (C) 2010 Ethan Gruber
	EADitor: https://github.com/ewg118/eaditor
	Apache License 2.0: https://github.com/ewg118/eaditor
	
-->
<p:config xmlns:p="http://www.orbeon.com/oxf/pipeline" xmlns:oxf="http://www.orbeon.com/oxf/processors">

	<p:param type="input" name="data"/>
	<p:param type="output" name="data"/>

	<p:processor name="oxf:request">
		<p:input name="config">
			<config>
				<include>/request</include>
			</config>
		</p:input>
		<p:output name="data" id="request"/>
	</p:processor>

	<p:processor name="oxf:pipeline">
		<p:input name="config" href="../models/config.xpl"/>
		<p:output name="data" id="config"/>
	</p:processor>
	
	<p:processor name="oxf:unsafe-xslt">		
		<p:input name="data" href="#config"/>
		<p:input name="config">
			<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:template match="/">
					<collection-type>
						<xsl:value-of select="/config/collection_type"/>
					</collection-type>
				</xsl:template>
			</xsl:stylesheet>
		</p:input>
		<p:output name="data" id="collection-type-config"/>
	</p:processor>
	
	<p:choose href="#collection-type-config">
		<p:when test="collection-type='cointype'">			
			<p:processor name="oxf:pipeline">
				<p:input name="config" href="../models/xquery/aggregate-all.xpl"/>
				<p:output name="data" id="model"/>
			</p:processor>
			
			<p:processor name="oxf:pipeline">
				<p:input name="config" href="../views/serializations/object/rdf.xpl"/>
				<p:input name="data" href="#model"/>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:when>
		<p:otherwise>
			<p:processor name="oxf:unsafe-xslt">
				<p:input name="request" href="#request"/>
				<p:input name="data" href="#config"/>
				<p:input name="config">
					<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
						<xsl:variable name="collection-name" select="substring-before(substring-after(doc('input:request')/request/request-uri, 'numishare/'), '/')"/>				
						<!-- config variables -->
						<xsl:variable name="solr-url" select="concat(/config/solr_published, 'select/')"/>
						
						<xsl:variable name="service">
							<xsl:value-of select="concat($solr-url, '?q=collection-name:', $collection-name, '+AND+NOT(lang:*)+AND+coinType_uri:*&amp;rows=100000&amp;fl=id,recordId,title_display,coinType_uri,objectType_uri,recordType,publisher_display,axis_num,diameter_num,height_num,width_num,taq_num,weight_num,thumbnail_obv,reference_obv,thumbnail_rev,reference_rev,findspot_uri,findspot_geo,collection_uri&amp;mode=nomisma')"/>
						</xsl:variable>
						
						<xsl:template match="/">
							<config>
								<url>
									<xsl:value-of select="$service"/>
								</url>
								<content-type>application/xml</content-type>
								<encoding>utf-8</encoding>
							</config>
						</xsl:template>
					</xsl:stylesheet>
				</p:input>
				<p:output name="data" id="generator-config"/>
			</p:processor>
			
			<p:processor name="oxf:url-generator">
				<p:input name="config" href="#generator-config"/>
				<p:output name="data" id="model"/>
			</p:processor>
			
			<p:processor name="oxf:pipeline">
				<p:input name="data" href="#model"/>
				<p:input name="config" href="../views/serializations/solr/rdf.xpl"/>
				<p:output name="data" ref="data"/>
			</p:processor>
		</p:otherwise>
	</p:choose>	
</p:config>
