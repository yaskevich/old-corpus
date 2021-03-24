<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet  [
	<!ENTITY nbsp   "&#160;">
	<!ENTITY mdash  "&#8212;">
	<!ENTITY ldquo  "&#8220;">
	<!ENTITY rdquo  "&#8221;"> 
]>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template name="th_number_minus">
  <xsl:param name="i">1</xsl:param>
  <xsl:if test="$i &gt; 0">
    <th align="left">
		<b><xsl:value-of select="$i"/></b>
	</th>
    <xsl:call-template name="th_number_minus">
		<xsl:with-param name="i" select="$i - 1"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template name="th_number_plus">
  <xsl:param name="i">1</xsl:param>
  <xsl:param name="ii">1</xsl:param>
  <xsl:if test="$i &lt;= $ii">
    <th align="left">
		<b><xsl:value-of select="$i"/></b>
	</th>
    <xsl:call-template name="th_number_plus">
		<xsl:with-param name="i" select="$i + 1"/>
		<xsl:with-param name="ii" select="$ii"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template name="perf">
SQL <xsl:value-of select="format-number (number(data/report/dbtime/text()), '#0.00')"/> sec
+
XML <xsl:value-of select="format-number (number(data/report/xmltime/text()), '#0.00')"/> sec
</xsl:template>


<xsl:template match="/">
	<xsl:variable name="count_concordance" select="count(data/concordance/cluster)" />
	<xsl:variable name="count_freq" select="count(data/freq/score)" />
	<xsl:variable name="form_tokens" select="data/freq/@forms" />
	
	<xsl:if test="boolean(data/concordance)">
		<div style="width:600px;margin-bottom:15px;height:20px;">
			<span style="background-color:lightgreen;border: solid 1px navy;margin-right:20px;padding-right:4px;padding-left:4px;">Term: <b><xsl:value-of select="data/report/term/text()"/></b>
			</span>
			<span style="background-color:yellow;color:red;border: solid 1px black;padding-right:4px;padding-left:4px;">Found: 
				<b><xsl:value-of select="$count_concordance"/></b> in <i><xsl:call-template name="perf" /></i>
			</span>
		</div>
	</xsl:if>
	<xsl:if test="$count_freq">
		<div style="margin-bottom:15px;">
			<span style="background-color:pink;color:navy;border: solid 1px black;padding-right:4px;padding-left:4px;">Forms: 
				<b><xsl:value-of select="$count_freq"/></b> 
				[from <b><xsl:value-of select="$form_tokens"/></b> tokens]
				in 
				 <i><xsl:call-template name="perf" /></i>
			</span>
		</div>
		<table>
			<tr><th>Score</th><th>Count</th><th>Share</th><th>Form</th></tr>
			<xsl:apply-templates select="data/freq/score" mode="table">
				<xsl:sort order="descending" data-type="number" select="count/text()"/>
				<xsl:with-param name="percent" select="100 div number($form_tokens)"/>
			</xsl:apply-templates>
		</table>
	</xsl:if>
	<xsl:if test="$count_concordance != 0">
		<table id="table1">
			<!--
			<tr>
			<th align="left">№</th>
			<xsl:call-template name="th_number_minus"><xsl:with-param name="i" select="data/report/left/text()"/></xsl:call-template>
			<th align="center">term</th>
			<xsl:call-template name="th_number_plus"><xsl:with-param name="ii" select="data/report/right/text()"/></xsl:call-template>
			</tr>
			-->
			<xsl:apply-templates select="data/concordance/cluster" mode="table">
				<!-- <xsl:sort order="descending" data-type="number" select="@n"/> -->
				<!-- <xsl:sort order="ascending" data-type="text" select="token[@left = 1]"/> -->
				<!-- <xsl:sort order="ascending" data-type="text" select="token[@right = 1]"/> -->
				<xsl:sort order="ascending" data-type="text" select="item[@center]/form/text()"/>
			</xsl:apply-templates> 
		</table>
	</xsl:if>
</xsl:template>

<xsl:template match="score" mode="table">
<xsl:param name="percent">1</xsl:param>
<xsl:variable name="occurency" select="count/text()" />

<tr>
	<td>
		<xsl:value-of select="position()"/>
	</td>
	<td>
		<xsl:value-of select="$occurency"/>
	</td>
	<td>
		<xsl:value-of select="format-number (($percent * $occurency), '#0.###')"/>%
	</td>
	<td>
		<xsl:value-of select="form/text()"/>
		</td>
	
</tr>
</xsl:template>

<xsl:template match="cluster" mode="table">
<tr> 
	 <td>
		<i><xsl:value-of select="@n"/></i>
	</td>
	<td style="text-align:right;">
	<xsl:apply-templates select="item[@left]" mode="table" >
		<xsl:sort order="descending" data-type="number" select="@left"/>
	</xsl:apply-templates>
	</td>
	<td style="text-align:left;">
		<b><xsl:value-of select="item[@center]/token/text()"/></b>
	</td>
	<td style="text-align:left;">	
	<xsl:apply-templates select="item[@right]" mode="table" >
		<xsl:sort order="ascending" data-type="number" select="@right"/>
	</xsl:apply-templates>
	</td>
      </tr> 
</xsl:template>

<xsl:template match="item" mode="table">
	<xsl:variable name="form" select="form/text()" />
	<!-- <td> -->
		<span class="token" data-form="{$form}"><xsl:value-of select="token/text()"/></span>
		<span>&nbsp;</span>
	<!-- </td> -->
</xsl:template>

</xsl:stylesheet>