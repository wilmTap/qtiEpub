<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:qti="http://www.imsglobal.org/xsd/imsqti_v2p1" xmlns="http://www.w3.org/1999/xhtml">
    <xsl:template match="qti:assessmentItem">
        <html>
            <head>
                <title>
                    <xsl:value-of select="@title"/>
                </title>
                <meta name="qti.identifier" content="{@identifier}"/>
                <meta name="qti.adaptive" content="{@adaptive}"/>
                <meta name="qti.timeDependent" content="{@timeDependent}"/>
                <link rel="stylesheet" type="text/css" href="qti2html.css"/>
            </head>
            <body>
                <h2>
                    <xsl:value-of select="@title"/>
                </h2>
                <xsl:for-each select="qti:itemBody">
                    <xsl:call-template name="qti2div"/>
                </xsl:for-each>
                <xsl:if test="qti:outcomeDeclaration | qti:responseProcessing">
                    <div class="qti-outcomes">
                        <xsl:if test="qti:responseProcessing/@template">
                            <xsl:attribute name="data-template">
                                <xsl:value-of select="qti:responseProcessing/@template"/>
                            </xsl:attribute>
                        </xsl:if>
                        <h3>Outcomes</h3>
                        <table>
                            <tr>
                                <th>identifier</th>
                                <th>baseType</th>
                                <th>cardinality</th>
                                <th>default</th>
                            </tr>
                            <xsl:for-each select="qti:outcomeDeclaration">
                                <tr class="qti-outcomeDeclaration">
                                    <td>
                                        <xsl:value-of select="@identifier"/>
                                    </td>
                                    <td>
                                        <xsl:value-of select="@baseType"/>
                                    </td>
                                    <td>
                                        <xsl:value-of select="@cardinality"/>
                                    </td>
                                    <td>
                                        <dl class="qti-default">
                                            <xsl:if test="not(qti:defaultValue/qti:value)">
                                                <dt>NULL</dt>
                                            </xsl:if>
                                            <xsl:for-each select="qti:defaultValue/qti:value">
                                                <dd>
                                                  <xsl:value-of select="text()"/>
                                                </dd>
                                            </xsl:for-each>
                                        </dl>
                                    </td>
                                </tr>
                            </xsl:for-each>
                        </table>
                        <xsl:if test="not(qti:responseProcessing/@template)">
                            <xsl:for-each select="qti:responseProcessing">
                                <xsl:call-template name="qti2div"/>
                            </xsl:for-each>
                        </xsl:if>
                    </div>
                </xsl:if>
            </body>
        </html>
    </xsl:template>
    <xsl:template name="qti2div">
        <xsl:choose>
            <xsl:when test="self::text()">
                <xsl:copy/>
            </xsl:when>
            <xsl:when test="self::qti:p | self::qti:img">
                <xsl:element name="{local-name(.)}" namespace="http://www.w3.org/1999/xhtml">
                    <xsl:copy-of select="@*"/>
                    <xsl:for-each select="child::node()">
                        <xsl:call-template name="qti2div"/>
                    </xsl:for-each>
                </xsl:element>
            </xsl:when>
            <xsl:when test="self::qti:choiceInteraction">
                <div class="qti-choiceInteraction" id="{@responseIdentifier}">
                    <xsl:variable name="response" select="@responseIdentifier"/>
                    <xsl:variable name="declaration"
                        select="//qti:responseDeclaration[@identifier=$response]"/>
                    <xsl:variable name="correct" select="$declaration/qti:correctResponse/qti:value"/>
                    <xsl:variable name="default" select="$declaration/qti:defaultValue/qti:value"/>
                    <xsl:attribute name="data-baseType">
                        <xsl:value-of select="$declaration/@baseType"/>
                    </xsl:attribute>
                    <xsl:attribute name="data-cardinality">
                        <xsl:value-of select="$declaration/@cardinality"/>
                    </xsl:attribute>
                    <xsl:for-each select="@shuffle  | @minChoices | @maxChoices">
                        <xsl:attribute name="data-{local-name(.)}">
                            <xsl:value-of select="."/>
                        </xsl:attribute>
                    </xsl:for-each>
                    <xsl:for-each select="$declaration/qti:mapping">
                        <xsl:for-each select="@lowerBound | @upperBound | @defaultValue">
                            <xsl:attribute name="data-{name()}">
                                <xsl:value-of select="."/>
                            </xsl:attribute>
                        </xsl:for-each>
                    </xsl:for-each>
                    <p class="qti-prompt">
                        <xsl:value-of select="qti:prompt/text()"/>
                    </p>
                    <ul class="qti-choiceInteraction">
                        <xsl:for-each select="qti:simpleChoice">
                            <xsl:variable name="choiceIdentifier" select="@identifier"/>
                            <li class="qti-simpleChoice" data-identifier="{$choiceIdentifier}">
                                <xsl:if
                                    test="$declaration/qti:correctResponse/qti:value/text() = $choiceIdentifier">
                                    <xsl:attribute name="data-correct">true</xsl:attribute>
                                </xsl:if>
                                <xsl:if
                                    test="$declaration/qti:defaultValue/qti:value/text() = $choiceIdentifier">
                                    <xsl:attribute name="data-default">true</xsl:attribute>
                                </xsl:if>
                                <xsl:for-each
                                    select="$declaration/qti:mapping/qti:mapEntry[@mapKey=$choiceIdentifier]">
                                    <xsl:attribute name="data-score">
                                        <xsl:value-of select="@mappedValue"/>
                                    </xsl:attribute>
                                </xsl:for-each>
                                <xsl:if test="@fixed">
                                    <xsl:attribute name="data-fixed">
                                        <xsl:value-of select="@fixed"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:for-each select="child::node()">
                                    <xsl:call-template name="qti2div"/>
                                </xsl:for-each>
                            </li>
                        </xsl:for-each>
                    </ul>
                </div>
            </xsl:when>
            <xsl:when test="self::*">
                <xsl:element name="div" namespace="http://www.w3.org/1999/xhtml">
                    <xsl:attribute name="class">qti-<xsl:value-of select="local-name(.)"
                        /></xsl:attribute>
                    <xsl:for-each select="attribute::*">
                        <xsl:attribute name="data-{local-name(.)}">
                            <xsl:value-of select="."/>
                        </xsl:attribute>
                    </xsl:for-each>
                    <xsl:for-each select="child::node()">
                        <xsl:call-template name="qti2div"/>
                    </xsl:for-each>
                </xsl:element>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
