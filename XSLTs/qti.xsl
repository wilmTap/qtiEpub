<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns="http://www.w3.org/1999/xhtml" xmlns:h="http://www.w3.org/1999/xhtml"
    xmlns:qti="http://www.imsglobal.org/xsd/imsqti_v2p1" exclude-result-prefixes="h">
    <xsl:template match="h:head">
        <xsl:element name="head" namespace="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates select="@* | node()"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="h:body">
        <xsl:element name="body" namespace="http://www.w3.org/1999/xhtml">
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="onload">SetupPage()</xsl:attribute>
            <xsl:element name="script" namespace="http://www.w3.org/1999/xhtml">
                <xsl:attribute name="type">text/javascript</xsl:attribute>
                <xsl:attribute name="src">qtiengine.js</xsl:attribute>
            </xsl:element>
            <xsl:element name="script" namespace="http://www.w3.org/1999/xhtml">
                <xsl:attribute name="type">text/javascript</xsl:attribute><![CDATA[
function SetupPage () {
    InitBuiltins();]]><xsl:for-each select="//h:div[@class='qti-choiceInteraction']"><![CDATA[
    InitChoiceInteraction(']]><xsl:value-of select="@id"/><![CDATA[');]]></xsl:for-each>
                <xsl:for-each select="//h:tr[@class='qti-outcomeDeclaration']"><![CDATA[
    InitOutcome(']]><xsl:value-of select="h:td[1]/text()"/><![CDATA[');]]></xsl:for-each>
                <xsl:if test="h:div[@class='qti-outcomes']/@data-template"><![CDATA[
    ResponseProcessingTemplate(']]><xsl:value-of
                        select="h:div[@class='qti-outcomes']/@data-template"/><![CDATA[');]]>
                </xsl:if>
                <![CDATA[
}]]>
            </xsl:element>
            <xsl:element name="form" namespace="http://www.w3.org/1999/xhtml">
                <xsl:attribute name="action"/>
                <xsl:attribute name="method">get</xsl:attribute>
                <div class="qti.builtins">
                    <input id="numAttempts" type="hidden" name="numAttempts" value="1"/>
                </div>
                <xsl:apply-templates select="h:div[@class='qti-itemBody']"/>
                <p>
                    <input type="submit" value="OK"/>
                </p>
            </xsl:element>
            <xsl:element name="div" namespace="http://www.w3.org/1999/xhtml">
                <xsl:attribute name="class">qti-outcomes</xsl:attribute>
                <table>
                    <tr>
                        <th>identifier</th>
                        <th>baseType</th>
                        <th>cardinality</th>
                        <th>value</th>
                    </tr>
                    <xsl:for-each select="//h:tr[@class='qti-outcomeDeclaration']">
                        <xsl:variable name="response" select="h:td[1]/text()"/>
                        <tr class="qti-outcomeDeclaration" id="{$response}">
                            <xsl:copy-of select="h:td[1]"/>
                            <xsl:copy-of select="h:td[2]"/>
                            <xsl:copy-of select="h:td[3]"/>
                            <td class="score">
                                <dl id="{$response}.value">
                                    <xsl:variable name="dd"
                                        select="//h:dl[@class='qti-default']/h:dd"/>
                                    <xsl:if test="not($dd)">
                                        <dt>NULL</dt>
                                    </xsl:if>
                                    <xsl:for-each select="$dd">
                                        <dd>
                                            <xsl:value-of select="text()"/>
                                        </dd>
                                    </xsl:for-each>
                                </dl>
                            </td>
                        </tr>
                    </xsl:for-each>
                </table>
            </xsl:element>
        </xsl:element>
    </xsl:template>
    <xsl:template match="h:div[@class='qti-choiceInteraction']">
        <xsl:variable name="response" select="@id"/>
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="h:p[@class='qti-prompt']"/>
            <xsl:if test="@data-shuffle = 'true'">
                <input type="hidden" id="{$response}.seq" name="{$response}.seq" value="x"/>
            </xsl:if>
            <dl>
                <xsl:variable name="type">
                    <xsl:choose>
                        <xsl:when test="@data-cardinality = 'single'">radio</xsl:when>
                        <xsl:otherwise>checkbox</xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:for-each select="h:ul/h:li">
                    <dd><xsl:copy-of select="@data-fixed"/><input type="{$type}" name="{$response}"
                            id="{$response}.{@data-identifier}" value="{@data-identifier}">
                            <xsl:if test="@data-correct">
                                <xsl:attribute name="data-correct">
                                    <xsl:value-of select="@data-correct"/>
                                </xsl:attribute>
                            </xsl:if>
                            <xsl:if test="@data-score">
                                <xsl:attribute name="data-score">
                                    <xsl:value-of select="@data-score"/>
                                </xsl:attribute>
                            </xsl:if>
                        </input>&#160;<xsl:apply-templates select="node()"/>
                    </dd>
                </xsl:for-each>
            </dl>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
