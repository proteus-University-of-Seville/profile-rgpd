<?xml version="1.0" encoding="utf-8"?>

<!-- ================================================================== -->
<!-- File    : processing_activity.xsl                                  -->
<!-- Content : PROTEUS XSLT for processing activities (RGPD profile)    -->
<!-- Author  : Amador Durán Toro                                        -->
<!-- Date    : 2026/10/18                                               -->
<!-- Version : 1.0                                                      -->
<!-- ================================================================== -->
<!-- The children of a processing activity (legal bases, exceptions,    -->
<!-- international transfers and risks) are shown as rows of its table, -->
<!-- in the order of article 30.1 RGPD, instead of as a list of names.  -->
<!-- ================================================================== -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:proteus="http://proteus.us.es"
  xmlns:proteus-utils="http://proteus.us.es/utils"
>

  <!-- ================================================================== -->
  <!-- booleanProperty: yes / no                                          -->
  <!-- ================================================================== -->

  <xsl:template match="booleanProperty">
    <xsl:choose>
      <xsl:when test="normalize-space(.) = 'true'">
        <xsl:value-of select="proteus-utils:i18n('archetype.enum_choices.yes')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="proteus-utils:i18n('archetype.enum_choices.no')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Helpers shared by the RGPD views                                   -->
  <!-- ================================================================== -->

  <!-- A row with a label and some content (only if there is content) -->
  <xsl:template name="rgpd_row">
    <xsl:param name="label"/>
    <xsl:param name="content"/>
    <xsl:if test="string-length(normalize-space($content)) > 0">
      <tr>
        <th><xsl:value-of select="$label"/></th>
        <td><xsl:copy-of select="$content"/></td>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- Plain names of the targets of a trace property, separated by commas -->
  <xsl:template name="rgpd_trace_names">
    <xsl:param name="property"/>
    <xsl:for-each select="$property/trace">
      <xsl:variable name="target" select="//object[@id = current()/@target]"/>
      <xsl:if test="$target">
        <xsl:value-of select="$target/properties/*[@name=':Proteus-name']"/>
        <xsl:if test="position() != last()">; </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- One legal basis: "6.1.c Obligación legal (norma)" -->
  <xsl:template name="rgpd_legal_basis">
    <xsl:value-of select="proteus-utils:i18n(concat('archetype.enum_choices.', properties/enumProperty[@name='legal-basis-type']))"/>
    <xsl:if test="normalize-space(properties/stringProperty[@name='enabling-law']) != ''">
      <xsl:text> (</xsl:text>
      <xsl:value-of select="properties/stringProperty[@name='enabling-law']"/>
      <xsl:text>)</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- One international transfer: "País: garantía" -->
  <xsl:template name="rgpd_transfer">
    <xsl:value-of select="properties/stringProperty[@name='country']"/>
    <xsl:text>: </xsl:text>
    <xsl:value-of select="proteus-utils:i18n(concat('archetype.enum_choices.', properties/enumProperty[@name='safeguard']))"/>
  </xsl:template>

  <!-- Children of a given class as list items, selectable from the GUI -->
  <xsl:template name="rgpd_children_list">
    <xsl:param name="children"/>
    <xsl:param name="mode"/>
    <ul class="traces rgpd_children">
      <xsl:for-each select="$children">
        <li id="{@id}" data-proteus-id="{@id}">
          <xsl:choose>
            <xsl:when test="$mode = 'legal-basis'">
              <xsl:call-template name="rgpd_legal_basis"/>
              <xsl:if test="normalize-space(properties/markdownProperty[@name='justification']) != ''">
                <div class="rgpd_detail">
                  <xsl:apply-templates select="properties/markdownProperty[@name='justification']"/>
                </div>
              </xsl:if>
            </xsl:when>
            <xsl:when test="$mode = 'exception'">
              <xsl:value-of select="proteus-utils:i18n(concat('archetype.enum_choices.', properties/enumProperty[@name='exception-type']))"/>
              <xsl:if test="normalize-space(properties/markdownProperty[@name='justification']) != ''">
                <div class="rgpd_detail">
                  <xsl:apply-templates select="properties/markdownProperty[@name='justification']"/>
                </div>
              </xsl:if>
            </xsl:when>
            <xsl:when test="$mode = 'transfer'">
              <xsl:call-template name="rgpd_transfer"/>
              <xsl:if test="properties/traceProperty[@name='transfer-recipient']/trace">
                <xsl:text> · </xsl:text>
                <xsl:call-template name="rgpd_trace_names">
                  <xsl:with-param name="property" select="properties/traceProperty[@name='transfer-recipient']"/>
                </xsl:call-template>
              </xsl:if>
              <xsl:if test="normalize-space(properties/markdownProperty[@name='safeguard-documentation']) != ''">
                <div class="rgpd_detail">
                  <xsl:apply-templates select="properties/markdownProperty[@name='safeguard-documentation']"/>
                </div>
              </xsl:if>
            </xsl:when>
            <xsl:when test="$mode = 'risk'">
              <xsl:if test="properties/codeProperty">
                <span class="object_code"><xsl:value-of select="properties/codeProperty"/></span>
                <xsl:text> </xsl:text>
              </xsl:if>
              <strong><xsl:value-of select="properties/*[@name=':Proteus-name']"/></strong>
              <div class="rgpd_detail">
                <xsl:value-of select="proteus-utils:i18n('archetype.prop_name.likelihood')"/>
                <xsl:text>: </xsl:text>
                <xsl:apply-templates select="properties/enumProperty[@name='likelihood']"/>
                <xsl:text> · </xsl:text>
                <xsl:value-of select="proteus-utils:i18n('archetype.prop_name.impact')"/>
                <xsl:text>: </xsl:text>
                <xsl:apply-templates select="properties/enumProperty[@name='impact']"/>
                <xsl:if test="properties/traceProperty[@name='mitigated-by']/trace">
                  <xsl:text> · </xsl:text>
                  <xsl:value-of select="proteus-utils:i18n('archetype.prop_name.mitigated-by')"/>
                  <xsl:text>: </xsl:text>
                  <xsl:call-template name="rgpd_trace_names">
                    <xsl:with-param name="property" select="properties/traceProperty[@name='mitigated-by']"/>
                  </xsl:call-template>
                </xsl:if>
              </div>
              <xsl:if test="normalize-space(properties/markdownProperty[@name='description']) != ''">
                <div class="rgpd_detail">
                  <xsl:apply-templates select="properties/markdownProperty[@name='description']"/>
                </div>
              </xsl:if>
            </xsl:when>
          </xsl:choose>
        </li>
      </xsl:for-each>
    </ul>
  </xsl:template>

  <!-- Rows for the children of a processing activity of a given class -->
  <xsl:template name="rgpd_children_row">
    <xsl:param name="class"/>
    <xsl:param name="label_key"/>
    <xsl:param name="mode"/>
    <xsl:variable name="children"
      select="children/object[contains(concat(' ', normalize-space(@classes), ' '), concat(' ', $class, ' '))]"/>
    <xsl:if test="$children">
      <tr>
        <th><xsl:value-of select="proteus-utils:i18n($label_key)"/></th>
        <td>
          <xsl:call-template name="rgpd_children_list">
            <xsl:with-param name="children" select="$children"/>
            <xsl:with-param name="mode" select="$mode"/>
          </xsl:call-template>
        </td>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- A property row by name -->
  <xsl:template name="rgpd_property_row">
    <xsl:param name="name"/>
    <xsl:for-each select="properties/*[@name = $name]">
      <xsl:call-template name="generate_property_row"/>
    </xsl:for-each>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- processing-activity template (RAT view)                            -->
  <!-- ================================================================== -->

  <xsl:template
    match="object[contains(concat(' ', normalize-space(@classes), ' '),' processing-activity ')]"
    name="processing_activity_template"
    priority="1"
  >
    <xsl:variable name="rows">
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'purposes'"/></xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'controller'"/></xsl:call-template>
      <xsl:call-template name="rgpd_children_row">
        <xsl:with-param name="class" select="'legal-basis'"/>
        <xsl:with-param name="label_key" select="'xslt.rgpd.legal_bases'"/>
        <xsl:with-param name="mode" select="'legal-basis'"/>
      </xsl:call-template>
      <xsl:call-template name="rgpd_children_row">
        <xsl:with-param name="class" select="'special-category-exception'"/>
        <xsl:with-param name="label_key" select="'xslt.rgpd.exceptions'"/>
        <xsl:with-param name="mode" select="'exception'"/>
      </xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'data-subjects'"/></xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'data-categories'"/></xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'recipients'"/></xsl:call-template>
      <xsl:call-template name="rgpd_children_row">
        <xsl:with-param name="class" select="'international-transfer'"/>
        <xsl:with-param name="label_key" select="'xslt.rgpd.transfers'"/>
        <xsl:with-param name="mode" select="'transfer'"/>
      </xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'retention'"/></xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'security-measures'"/></xsl:call-template>
      <xsl:call-template name="rgpd_children_row">
        <xsl:with-param name="class" select="'risk'"/>
        <xsl:with-param name="label_key" select="'xslt.rgpd.risks'"/>
        <xsl:with-param name="mode" select="'risk'"/>
      </xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'automated-decisions'"/></xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'dpia-required'"/></xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'status'"/></xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'review-date'"/></xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'comments'"/></xsl:call-template>
    </xsl:variable>

    <!-- Every property is excluded from the generic rows: they are in $rows -->
    <xsl:variable name="all_names">
      <xsl:text>,</xsl:text>
      <xsl:for-each select="properties/*"><xsl:value-of select="concat(@name, ',')"/></xsl:for-each>
    </xsl:variable>

    <xsl:call-template name="generate_table">
      <xsl:with-param name="excluded_properties" select="$all_names"/>
      <xsl:with-param name="extra_rows_before" select="$rows"/>
      <xsl:with-param name="show_children" select="false()"/>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
