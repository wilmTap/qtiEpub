<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns="http://www.imsglobal.org/xsd/imsqti_v2p1" xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <xsl:template match="html:html">
        <assessmentItem
            xsi:schemaLocation="http://www.imsglobal.org/xsd/imsqti_v2p1 http://www.imsglobal.org/xsd/imsqti_v2p1.xsd">
            <xsl:attribute name="title">
                <xsl:value-of select="html:head/html:title/text()"/>
            </xsl:attribute>
            <xsl:attribute name="identifier">
                <xsl:value-of select="html:head/html:meta[@name='qti.identifier']/@content"/>
            </xsl:attribute>
            <xsl:attribute name="adaptive">
                <xsl:value-of select="html:head/html:meta[@name='qti.adaptive']/@content"/>
            </xsl:attribute>
            <xsl:attribute name="timeDependent">
                <xsl:value-of select="html:head/html:meta[@name='qti.timeDependent']/@content"/>
            </xsl:attribute>
            <xsl:for-each select="//html:div[@class='qti-choiceInteraction']">
                <responseDeclaration identifier="{@id}" baseType="identifier">
                    <xsl:attribute name="cardinality">
                        <xsl:choose>
                            <xsl:when test="@data-cardinality">
                                <xsl:value-of select="@data-cardinality"/>
                            </xsl:when>
                            <xsl:otherwise>single</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:if test="html:ul/html:li[@data-correct='true']">
                        <correctResponse>
                            <xsl:for-each select="html:ul/html:li[@data-correct='true']">
                                <value>
                                    <xsl:value-of select="@data-identifier"/>
                                </value>
                            </xsl:for-each>
                        </correctResponse>
                    </xsl:if>
                    <xsl:if test="html:ul/html:li/@data-score">
                        <mapping>
                            <xsl:for-each
                                select="@data-lowerBound | @data-upperBound | @data-defaultValue">
                                <xsl:attribute name="{substring(local-name(.),6)}">
                                    <xsl:value-of select="."/>
                                </xsl:attribute>
                            </xsl:for-each>
                            <xsl:for-each select="html:ul/html:li[@data-score]">
                                <mapEntry mapKey="{@data-identifier}" mappedValue="{@data-score}"/>
                            </xsl:for-each>
                        </mapping>
                    </xsl:if>
                </responseDeclaration>
            </xsl:for-each>
            <xsl:variable name="outcomes" select="html:body/html:div[@class='qti-outcomes']"/>
            <xsl:for-each select="$outcomes//html:tr[@class='qti-outcomeDeclaration']">
                <outcomeDeclaration identifier="{html:td[1]/text()}" baseType="{html:td[2]/text()}"
                    cardinality="{html:td[3]/text()}">
                    <xsl:if test="//html:dl[@class='qti-default']">
                        <defaultValue>
                            <xsl:for-each select="//html:dl[@class='qti-default']/html:dd">
                                <value>
                                    <xsl:value-of select="text()"/>
                                </value>
                            </xsl:for-each>
                        </defaultValue>
                    </xsl:if>
                </outcomeDeclaration>
            </xsl:for-each>
            <xsl:for-each select="html:body/html:div[@class='qti-itemBody']">
                <xsl:call-template name="div2qti"/>
            </xsl:for-each>
            <xsl:choose>
                <xsl:when test="$outcomes/@data-template">
                    <responseProcessing template="{$outcomes/@data-template}"/>
                </xsl:when>
                <xsl:when test="$outcomes/html:div[@class='qti-responseProcessing']">
                    <xsl:for-each select="$outcomes/html:div[@class='qti-responseProcessing']">
                        <xsl:call-template name="div2qti"/>
                    </xsl:for-each>
                </xsl:when>
            </xsl:choose>
        </assessmentItem>
    </xsl:template>
    <xsl:template name="div2qti">
        <xsl:choose>
            <xsl:when test="self::text()">
                <xsl:copy/>
            </xsl:when>
            <xsl:when test="self::html:p | self::html:img">
                <xsl:element name="{local-name(.)}"
                    namespace="http://www.imsglobal.org/xsd/imsqti_v2p1">
                    <xsl:copy-of select="@*"/>
                    <xsl:for-each select="child::node()">
                        <xsl:call-template name="div2qti"/>
                    </xsl:for-each>
                </xsl:element>
            </xsl:when>
            <xsl:when test="self::html:div[@class='qti-choiceInteraction']">
                <choiceInteraction>
                    <xsl:attribute name="responseIdentifier">
                        <xsl:value-of select="@id"/>
                    </xsl:attribute>
                    <xsl:for-each select="@data-shuffle | @data-maxChoices | @data-minChoices">
                        <xsl:attribute name="{substring(local-name(.),6)}">
                            <xsl:value-of select="."/>
                        </xsl:attribute>
                    </xsl:for-each>
                    <prompt>
                        <xsl:for-each select="html:p[@class='qti-prompt']/child::node()">
                            <xsl:call-template name="div2qti"/>
                        </xsl:for-each>
                    </prompt>
                    <xsl:for-each select="html:ul/html:li">
                        <simpleChoice identifier="{@data-identifier}">
                            <xsl:if test="@data-fixed">
                                <xsl:attribute name="fixed">
                                    <xsl:value-of select="@data-fixed"/>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:for-each select="child::node()">
                                <xsl:call-template name="div2qti"/>
                            </xsl:for-each>
                        </simpleChoice>
                    </xsl:for-each>
                </choiceInteraction>
            </xsl:when>
            <xsl:when test="self::html:div">
                <xsl:choose>
                    <xsl:when test="starts-with(@class,'qti-')">
                        <xsl:element name="{substring(@class,5)}"
                            namespace="http://www.imsglobal.org/xsd/imsqti_v2p1">
                            <xsl:for-each select="attribute::*">
                                <xsl:if test="starts-with(local-name(),'data-')">
                                    <xsl:attribute name="{substring(local-name(.),6)}">
                                        <xsl:value-of select="."/>
                                    </xsl:attribute>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:for-each select="child::node()">
                                <xsl:call-template name="div2qti"/>
                            </xsl:for-each>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="child::node()">
                            <xsl:call-template name="div2qti"/>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
