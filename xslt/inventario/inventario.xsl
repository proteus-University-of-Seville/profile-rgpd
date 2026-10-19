<?xml version="1.0" encoding="utf-8"?>

<!-- ================================================================== -->
<!-- File    : inventario.xsl                                           -->
<!-- Content : PROTEUS view of the public inventory of processing       -->
<!--           activities (art. 31.2 LOPDGDD) of a RAT document         -->
<!-- Author  : Amador Durán Toro                                        -->
<!-- Date    : 2026/10/18                                               -->
<!-- Version : 1.0                                                      -->
<!-- ================================================================== -->
<!-- Only the activities whose status is 'active' are shown, and only   -->
<!-- the information of article 30.1 RGPD plus the legal basis: risks,  -->
<!-- impact assessments and internal data are left out. The core and    -->
<!-- the resources of the default view are reused.                      -->
<!-- ================================================================== -->

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:proteus="http://proteus.us.es"
  xmlns:proteus-utils="http://proteus.us.es/utils"
  exclude-result-prefixes="proteus"
>
  <xsl:output
    method="html"
    doctype-system="about:legacy-compat"
    omit-xml-declaration="yes" encoding="utf-8" indent="yes"
  />

  <!-- Core modules of the default view -->
  <xsl:include href="../default/core/utilities.xsl" />
  <xsl:include href="../default/core/generate_table.xsl" />
  <xsl:include href="../default/core/properties.xsl" />
  <xsl:include href="../default/archetypes/rat/processing_activity.xsl" />
  <xsl:include href="../default/archetypes/rat/rgpd_views.xsl" />

  <xsl:template match="project">
    <xsl:variable name="currentDocumentId" select="proteus-utils:current_document()"/>
    <xsl:apply-templates select="documents/object[@id=$currentDocumentId]" mode="rgpd_inventory"/>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Document                                                           -->
  <!-- ================================================================== -->

  <xsl:template match="object" mode="rgpd_inventory">
    <xsl:call-template name="rgpd_view_document">
      <xsl:with-param name="title_key" select="'xslt.rgpd.inventory_title'"/>
      <xsl:with-param name="intro_key" select="'xslt.rgpd.inventory_intro'"/>
      <xsl:with-param name="help_key" select="'xslt.rgpd.inventory_help'"/>
      <xsl:with-param name="mode" select="'inventory'"/>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
