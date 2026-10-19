<?xml version="1.0" encoding="utf-8"?>

<!-- ================================================================== -->
<!-- File    : rgpd_views.xsl                                           -->
<!-- Content : Templates shared by the 'inventario' and 'clausulas'     -->
<!--           views of the RGPD profile                                -->
<!-- Author  : Amador Durán Toro                                        -->
<!-- Date    : 2026/10/18                                               -->
<!-- Version : 1.0                                                      -->
<!-- ================================================================== -->
<!-- Both views show only the processing activities whose status is     -->
<!-- 'active'. They need processing_activity.xsl (helpers) and the core -->
<!-- modules of the default view.                                       -->
<!-- ================================================================== -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:proteus="http://proteus.us.es"
  xmlns:proteus-utils="http://proteus.us.es/utils"
>

  <!-- ================================================================== -->
  <!-- HTML document of a view                                            -->
  <!-- ================================================================== -->

  <xsl:template name="rgpd_view_document">
    <xsl:param name="title_key"/>
    <xsl:param name="intro_key"/>
    <xsl:param name="help_key"/>
    <xsl:param name="mode"/>

    <xsl:variable name="controller" select="(.//object[contains(concat(' ', normalize-space(@classes), ' '), ' data-controller ')])[1]"/>
    <xsl:variable name="activities"
      select=".//object[contains(concat(' ', normalize-space(@classes), ' '), ' processing-activity ')]
                       [properties/enumProperty[@name='status'] = 'active']"/>

    <html>
      <head>
        <meta charset="utf-8"/>
        <meta name="generatedBy" content="PROTEUS"/>
        <link rel="stylesheet" href="templates:///default/resources/css/default.css"/>
        <title>
          <xsl:value-of select="proteus-utils:i18n($title_key)"/>
        </title>
      </head>

      <body>
        <!-- Help for the PROTEUS user, not part of the document: it is hidden -->
        <!-- by default and when printing (PDF export), and shown by the       -->
        <!-- script at the end only inside PROTEUS, so that it does not appear -->
        <!-- in the HTML export either.                                        -->
        <div class="rgpd_view_help">
          <strong><xsl:value-of select="proteus-utils:i18n('xslt.rgpd.view_help_title')"/></strong>
          <xsl:text> </xsl:text>
          <xsl:value-of select="proteus-utils:i18n($help_key)"/>
        </div>

        <h1><xsl:value-of select="proteus-utils:i18n($title_key)"/></h1>
        <p class="rgpd_intro">
          <xsl:value-of select="proteus-utils:i18n($intro_key, string($controller/properties/*[@name=':Proteus-name']))"/>
        </p>

        <xsl:for-each select="$activities">
          <xsl:choose>
            <xsl:when test="$mode = 'inventory'">
              <xsl:call-template name="rgpd_inventory_activity"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="rgpd_clause_activity"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>

        <xsl:if test="not($activities)">
          <p class="rgpd_intro">
            <xsl:value-of select="proteus-utils:i18n('xslt.rgpd.no_active_activities')"/>
          </p>
        </xsl:if>

        <script src="qrc:///qtwebchannel/qwebchannel.js"></script>
        <script src="templates:///default/resources/javascript/proteus.js"></script>
        <script>
          // Show the help only inside PROTEUS (web channel available)
          if (window.qt &amp;&amp; window.qt.webChannelTransport) {
            document.querySelectorAll('.rgpd_view_help').forEach(function (e) { e.style.display = 'block'; });
          }
        </script>
      </body>
    </html>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Common pieces                                                      -->
  <!-- ================================================================== -->

  <!-- Controller of the current activity (or the first one of the document) -->
  <xsl:template name="rgpd_controller_name">
    <xsl:variable name="traced" select="//object[@id = current()/properties/traceProperty[@name='controller']/trace/@target]"/>
    <xsl:variable name="controller"
      select="($traced | //object[not($traced)][contains(concat(' ', normalize-space(@classes), ' '), ' data-controller ')])[1]"/>
    <xsl:value-of select="$controller/properties/*[@name=':Proteus-name']"/>
    <xsl:if test="normalize-space($controller/properties/*[@name='tax-id']) != ''">
      <xsl:text> (</xsl:text>
      <xsl:value-of select="proteus-utils:i18n('archetype.prop_name.tax-id')"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="$controller/properties/*[@name='tax-id']"/>
      <xsl:text>)</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- Legal bases of the current activity, one per line -->
  <xsl:template name="rgpd_legal_bases_text">
    <xsl:for-each select="children/object[contains(concat(' ', normalize-space(@classes), ' '), ' legal-basis ')]">
      <div><xsl:call-template name="rgpd_legal_basis"/></div>
    </xsl:for-each>
    <xsl:for-each select="children/object[contains(concat(' ', normalize-space(@classes), ' '), ' special-category-exception ')]">
      <div>
        <xsl:value-of select="proteus-utils:i18n(concat('archetype.enum_choices.', properties/enumProperty[@name='exception-type']))"/>
      </div>
    </xsl:for-each>
  </xsl:template>

  <!-- International transfers of the current activity, one per line -->
  <xsl:template name="rgpd_transfers_text">
    <xsl:variable name="transfers" select="children/object[contains(concat(' ', normalize-space(@classes), ' '), ' international-transfer ')]"/>
    <xsl:for-each select="$transfers">
      <div><xsl:call-template name="rgpd_transfer"/></div>
    </xsl:for-each>
    <xsl:if test="not($transfers)">
      <xsl:value-of select="proteus-utils:i18n('xslt.rgpd.no_transfers')"/>
    </xsl:if>
  </xsl:template>

  <!-- Table of an activity: header with code and name plus the given rows. -->
  <!-- The class of the header pill (and its icon) can be changed.          -->
  <xsl:template name="rgpd_activity_table">
    <xsl:param name="rows"/>
    <xsl:param name="class" select="'processing-activity'"/>
    <xsl:variable name="all_names">
      <xsl:text>,</xsl:text>
      <xsl:for-each select="properties/*"><xsl:value-of select="concat(@name, ',')"/></xsl:for-each>
    </xsl:variable>
    <xsl:call-template name="generate_table">
      <xsl:with-param name="class" select="$class"/>
      <xsl:with-param name="excluded_properties" select="$all_names"/>
      <xsl:with-param name="extra_rows_before" select="$rows"/>
      <xsl:with-param name="show_children" select="false()"/>
    </xsl:call-template>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Inventory (art. 31.2 LOPDGDD)                                      -->
  <!-- ================================================================== -->

  <xsl:template name="rgpd_inventory_activity">
    <xsl:variable name="rows">
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('xslt.rgpd.controller')"/>
        <xsl:with-param name="content"><xsl:call-template name="rgpd_controller_name"/></xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'purposes'"/></xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('xslt.rgpd.legal_bases')"/>
        <xsl:with-param name="content"><xsl:call-template name="rgpd_legal_bases_text"/></xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('archetype.prop_name.data-subjects')"/>
        <xsl:with-param name="content">
          <xsl:call-template name="rgpd_trace_names"><xsl:with-param name="property" select="properties/traceProperty[@name='data-subjects']"/></xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('archetype.prop_name.data-categories')"/>
        <xsl:with-param name="content">
          <xsl:call-template name="rgpd_trace_names"><xsl:with-param name="property" select="properties/traceProperty[@name='data-categories']"/></xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('archetype.prop_name.recipients')"/>
        <xsl:with-param name="content">
          <xsl:call-template name="rgpd_trace_names"><xsl:with-param name="property" select="properties/traceProperty[@name='recipients']"/></xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('xslt.rgpd.transfers')"/>
        <xsl:with-param name="content"><xsl:call-template name="rgpd_transfers_text"/></xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_property_row"><xsl:with-param name="name" select="'retention'"/></xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('archetype.prop_name.security-measures')"/>
        <xsl:with-param name="content">
          <xsl:call-template name="rgpd_trace_names"><xsl:with-param name="property" select="properties/traceProperty[@name='security-measures']"/></xsl:call-template>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>

    <xsl:call-template name="rgpd_activity_table">
      <xsl:with-param name="rows" select="$rows"/>
    </xsl:call-template>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Information clause (basic layer, AEPD model)                       -->
  <!-- ================================================================== -->

  <xsl:template name="rgpd_clause_activity">
    <xsl:variable name="traced" select="//object[@id = current()/properties/traceProperty[@name='controller']/trace/@target]"/>
    <xsl:variable name="controller"
      select="($traced | //object[not($traced)][contains(concat(' ', normalize-space(@classes), ' '), ' data-controller ')])[1]"/>
    <xsl:variable name="dpos" select="//object[contains(concat(' ', normalize-space(@classes), ' '), ' dpo ')]"/>
    <xsl:variable name="dpo"
      select="($dpos[properties/traceProperty[@name='works-for']/trace/@target = $controller/@id] | $dpos)[1]"/>

    <xsl:variable name="rows">
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('xslt.rgpd.controller')"/>
        <xsl:with-param name="content">
          <xsl:call-template name="rgpd_controller_name"/>
          <xsl:for-each select="$controller/properties/*[@name='address' or @name='email'][normalize-space() != '']">
            <div><xsl:value-of select="."/></div>
          </xsl:for-each>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('xslt.rgpd.purpose')"/>
        <xsl:with-param name="content"><xsl:apply-templates select="properties/markdownProperty[@name='purposes']"/></xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('xslt.rgpd.legitimation')"/>
        <xsl:with-param name="content"><xsl:call-template name="rgpd_legal_bases_text"/></xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('archetype.prop_name.recipients')"/>
        <xsl:with-param name="content">
          <xsl:choose>
            <xsl:when test="properties/traceProperty[@name='recipients']/trace">
              <xsl:call-template name="rgpd_trace_names"><xsl:with-param name="property" select="properties/traceProperty[@name='recipients']"/></xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="proteus-utils:i18n('xslt.rgpd.no_recipients')"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:for-each select="children/object[contains(concat(' ', normalize-space(@classes), ' '), ' international-transfer ')]">
            <div>
              <xsl:value-of select="proteus-utils:i18n('xslt.rgpd.transfer_to')"/>
              <xsl:text> </xsl:text>
              <xsl:call-template name="rgpd_transfer"/>
            </div>
          </xsl:for-each>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('xslt.rgpd.retention')"/>
        <xsl:with-param name="content"><xsl:apply-templates select="properties/markdownProperty[@name='retention']"/></xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('xslt.rgpd.rights')"/>
        <xsl:with-param name="content"><xsl:apply-templates select="$controller/properties/markdownProperty[@name='rights-exercise']"/></xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('xslt.rgpd.dpo')"/>
        <xsl:with-param name="content"><xsl:value-of select="$dpo/properties/*[@name='public-contact']"/></xsl:with-param>
      </xsl:call-template>
      <xsl:call-template name="rgpd_row">
        <xsl:with-param name="label" select="proteus-utils:i18n('xslt.rgpd.complaint')"/>
        <xsl:with-param name="content">
          <!-- Supervisory authority traced from the controller, with its electronic office -->
          <xsl:variable name="authority"
            select="//object[@id = $controller/properties/traceProperty[@name='supervisory-authority']/trace[1]/@target]"/>
          <xsl:variable name="complaint_url">
            <xsl:choose>
              <xsl:when test="normalize-space($authority/properties/urlProperty[@name='complaint-url']) != ''">
                <xsl:value-of select="normalize-space($authority/properties/urlProperty[@name='complaint-url'])"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="normalize-space($authority/properties/urlProperty[@name='web'])"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:if test="$authority">
            <xsl:value-of select="proteus-utils:i18n('xslt.rgpd.complaint_text', string($authority/properties/*[@name=':Proteus-name']))"/>
            <xsl:if test="$complaint_url != ''">
              <div><a href="{$complaint_url}"><xsl:value-of select="$complaint_url"/></a></div>
            </xsl:if>
          </xsl:if>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>

    <xsl:call-template name="rgpd_activity_table">
      <xsl:with-param name="rows" select="$rows"/>
      <xsl:with-param name="class" select="'information-clause'"/>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
