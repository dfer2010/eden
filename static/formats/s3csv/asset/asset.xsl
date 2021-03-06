<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

    <!-- **********************************************************************
         Assets - CSV Import Stylesheet

         CSV fields:
         Organisation....................organisation_id.name & asset_log.organisation_id.name
         Acronym.........................organisation_id.acronym & asset_log.organisation_id.acronym
         Office..........................site_id & asset_log.site_id
         OfficeCode......................site_id.code & asset_log.site_id.code
         Catalog.........................supply_catalog_item.catalog_id.name
         Asset No........................number
         Type............................type
         Category........................supply_catalog_item.item_category_id
         Name............................supply_item.name
         Room............................asset_log.room_id
         Assigned To.....................pr_person.first_name
         Brand...........................supply_brand.name
         Model...........................supply_item.model
         SN..............................sn
         Supplier........................supplier
         Date............................purchase_date
         Price...........................purchase_price
         Comments........................comments

        creates:
            supply_brand.................
            org_office...................
            org_organisation.............
            gis_location.................
            supply_catalog...............
            supply_item_category.........
            supply_item..................
            supply_catalog_item..........
            pr_person....................
            org_room.....................

        @todo:
            - remove id column
            - make in-line references explicit

    *********************************************************************** -->
    <xsl:output method="xml"/>

    <xsl:key name="organisations" match="row" use="col[@field='Organisation']/text()"/>
    <xsl:key name="offices" match="row" use="concat(col[@field='Organisation']/text(), '|',
                                                         col[@field='Office']/text())"/>
    <xsl:key name="rooms" match="row" use="concat(col[@field='Organisation']/text(), '|',
                                                         col[@field='Office']/text(), '|',
                                                         col[@field='Room']/text())"/>
    <xsl:key name="persons" match="row" use="col[@field='Assigned To']/text()"/>
    <xsl:key name="brands" match="row" use="col[@field='Brand']/text()"/>
    <xsl:key name="catalogs" match="row" use="col[@field='Catalog']/text()"/>
    <xsl:key name="categories" match="row" use="concat(col[@field='Catalog']/text(), '|',
                                                       col[@field='Category']/text())"/>
    <xsl:key name="supply_items" match="row" use="concat(col[@field='Name'], ', ',
                                                         col[@field='Model'], ', ',
                                                         col[@field='Brand'])"/>
    <xsl:key name="supplier_organisation" match="row" use="col[@field='Supplier/Donor']"/>

    <!-- ****************************************************************** -->

    <xsl:template match="/">
        <s3xml>
            <!-- Organisations -->
            <xsl:for-each select="//row[generate-id(.)=
                                        generate-id(key('organisations',
                                                        col[@field='Organisation']/text())[1])]">
                <xsl:call-template name="Organisation">
                    <xsl:with-param name="OrgName" select="col[@field='Organisation']/text()"/>
                    <xsl:with-param name="OrgAcronym" select="col[@field='Acronym']/text()"/>
                </xsl:call-template>
            </xsl:for-each>

            <!-- Offices -->
            <xsl:for-each select="//row[generate-id(.)=
                                        generate-id(key('offices',
                                                        concat(col[@field='Organisation']/text(), '|',
                                                               col[@field='Office']/text()))[1])]">
                <xsl:call-template name="Office"/>
            </xsl:for-each>

            <!-- Rooms -->
            <xsl:for-each select="//row[generate-id(.)=
                                        generate-id(key('rooms',
                                                        concat(col[@field='Organisation']/text(), '|',
                                                               col[@field='Office']/text(), '|',
                                                               col[@field='Room']/text()))[1])]">
                <xsl:call-template name="Room"/>
            </xsl:for-each>

            <!-- Persons -->
            <xsl:for-each select="//row[generate-id(.)=
                                        generate-id(key('persons',
                                                        col[@field='Assigned To']/text())[1])]">
                <xsl:call-template name="Person"/>
            </xsl:for-each>

            <!-- Brands -->
            <xsl:for-each select="//row[generate-id(.)=
                                        generate-id(key('brands',
                                                        col[@field='Brand']/text())[1])]">
                <xsl:call-template name="Brand"/>
            </xsl:for-each>

            <!-- SupplyCatalogs -->
            <xsl:for-each select="//row[generate-id(.)=
                                        generate-id(key('catalogs',
                                                        col[@field='Catalog']/text())[1])]">
                <xsl:call-template name="SupplyCatalog"/>
            </xsl:for-each>

            <!-- SupplyItemCategories -->
            <xsl:for-each select="//row[generate-id(.)=
                                        generate-id(key('categories',
                                                        concat(col[@field='Catalog']/text(), '|',
                                                               col[@field='Category']/text()))[1])]">
                <xsl:call-template name="SupplyItemCategory"/>
            </xsl:for-each>

            <!-- SupplyItems -->
            <xsl:for-each select="//row[generate-id(.)=
                                        generate-id(key('supply_items',
                                                        concat(col[@field='Name'], ', ',
                                                               col[@field='Model'], ', ',
                                                               col[@field='Brand']))[1])]">
                <xsl:call-template name="SupplyItem"/>
            </xsl:for-each>

            <xsl:for-each select="//row[generate-id(.)=generate-id(key('supplier_organisation', col[@field='Supplier/Donor'])[1])]">
                <xsl:call-template name="Organisation">
                    <xsl:with-param name="OrgName" select="col[@field='Supplier/Donor']"/>
                </xsl:call-template>
            </xsl:for-each>

            <xsl:apply-templates select="table/row"/>
        </s3xml>
    </xsl:template>

    <!-- ****************************************************************** -->
    <xsl:template match="row">

        <xsl:variable name="OrgName" select="col[@field='Organisation']/text()"/>
        <xsl:variable name="OfficeName" select="col[@field='Office']/text()"/>
        <xsl:variable name="OfficeID" select="concat($OrgName, '|', $OfficeName)"/>
        <xsl:variable name="RoomName" select="col[@field='Room']/text()"/>
        <xsl:variable name="RoomID" select="concat($OrgName, '|', $OfficeName, '|', $RoomName)"/>

        <xsl:variable name="CatalogName" select="col[@field='Catalog']/text()"/>
        <xsl:variable name="CategoryName" select="col[@field='Category']/text()"/>
        <xsl:variable name="ItemCode" select="concat(col[@field='Name'], ', ',
                                                     col[@field='Model'], ', ',
                                                     col[@field='Brand'])"/>

        <xsl:variable name="Name" select="col[@field='Name']/text()"/>
        <xsl:variable name="BrandName" select="col[@field='Brand']/text()"/>
        <xsl:variable name="Model" select="col[@field='Model']/text()"/>
        <xsl:variable name="PersonName" select="col[@field='Assigned To']/text()"/>
        <xsl:variable name="AssetNumber" select="col[@field='Asset No']/text()"/>
        <xsl:variable name="Date" select="col[@field='Date']/text()"/>

        <!-- Asset  -->
        <resource name="asset_asset">
            <xsl:attribute name="tuid">
                <xsl:value-of select="col[@field='id']/text()"/>
            </xsl:attribute>
            <xsl:if test="$AssetNumber != ''">
                <data field="number"><xsl:value-of select="$AssetNumber"/></data>
            </xsl:if>
            <xsl:if test="col[@field='SN'] != ''">
                <data field="sn"><xsl:value-of select="col[@field='SN']"/></data>
            </xsl:if>
            <xsl:if test="col[@field='Type'] != ''">
                <xsl:choose>
                    <xsl:when test="col[@field='Type']=1">
                        <data field="type">1</data>
                    </xsl:when>
                    <xsl:when test="col[@field='Type']='VEHICLE'">
                        <data field="type">1</data>
                    </xsl:when>
                    <xsl:when test="col[@field='Type']='Vehicle'">
                        <data field="type">1</data>
                    </xsl:when>
                    <xsl:when test="col[@field='Type']='vehicle'">
                        <data field="type">1</data>
                    </xsl:when>
                </xsl:choose>
            </xsl:if>
            <!-- Link to Supplier/Donor org -->
            <reference field="supply_org_id" resource="org_organisation">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="col[@field='Supplier/Donor']/text()"/>
                </xsl:attribute>
            </reference>
            <xsl:if test="col[@field='Date'] != ''">
                <data field="purchase_date"><xsl:value-of select="col[@field='Date']"/></data>
            </xsl:if>
            <xsl:if test="col[@field='Price'] != ''">
                <data field="purchase_price"><xsl:value-of select="col[@field='Price']"/></data>
            </xsl:if>
            <xsl:if test="col[@field='Comments'] != ''">
                <data field="comments"><xsl:value-of select="col[@field='Comments']"/></data>
            </xsl:if>
            <reference field="item_id" resource="supply_item">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="$ItemCode"/>
                </xsl:attribute>
            </reference>
            <!-- Site -->
            <reference field="organisation_id" resource="org_organisation">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="$OrgName"/>
                </xsl:attribute>
            </reference>
            <reference field="site_id" resource="org_office">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="$OfficeID"/>
                </xsl:attribute>
            </reference>
        </resource>

    </xsl:template>

    <!-- ****************************************************************** -->
    <xsl:template name="Brand">
        <xsl:variable name="BrandName" select="col[@field='Brand']/text()"/>

        <resource name="supply_brand">
            <xsl:attribute name="tuid">
                <xsl:value-of select="$BrandName"/>
            </xsl:attribute>
            <data field="name"><xsl:value-of select="$BrandName"/></data>
        </resource>

    </xsl:template>

    <!-- ****************************************************************** -->
    <xsl:template name="Organisation">
        <xsl:param name="OrgName"/>
        <xsl:param name="OrgAcronym"/>

        <resource name="org_organisation">
            <xsl:attribute name="tuid">
                <xsl:value-of select="$OrgName"/>
            </xsl:attribute>
            <data field="name"><xsl:value-of select="$OrgName"/></data>
            <xsl:if test="$OrgAcronym!=''">
                <data field="acronym"><xsl:value-of select="$OrgAcronym"/></data>
            </xsl:if>
        </resource>
    </xsl:template>

    <!-- ****************************************************************** -->
    <xsl:template name="Office">

        <xsl:variable name="OrgName" select="col[@field='Organisation']/text()"/>
        <xsl:variable name="OfficeName" select="col[@field='Office']/text()"/>
        <xsl:variable name="OfficeID" select="concat($OrgName, '|', $OfficeName)"/>

        <resource name="org_office">
            <xsl:attribute name="tuid">
                <xsl:value-of select="$OfficeID"/>
            </xsl:attribute>
            <data field="name"><xsl:value-of select="$OfficeName"/></data>
            <xsl:if test="col[@field='OfficeCode'] != ''">
                <data field="code"><xsl:value-of select="col[@field='OfficeCode']"/></data>
            </xsl:if>
            <reference field="organisation_id" resource="org_organisation">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="$OrgName"/>
                </xsl:attribute>
            </reference>
        </resource>

    </xsl:template>

    <!-- ****************************************************************** -->
    <xsl:template name="SupplyCatalog">
        <xsl:variable name="CatalogName" select="col[@field='Catalog']/text()"/>

        <resource name="supply_catalog">
            <xsl:attribute name="tuid">
                <xsl:value-of select="$CatalogName"/>
            </xsl:attribute>
            <data field="name"><xsl:value-of select="$CatalogName"/></data>
        </resource>

    </xsl:template>

    <!-- ****************************************************************** -->
    <xsl:template name="SupplyItemCategory">
        <xsl:variable name="CatalogName" select="col[@field='Catalog']/text()"/>
        <xsl:variable name="CategoryName" select="col[@field='Category']/text()"/>
        <xsl:variable name="CategoryID" select="concat($CatalogName, '|', $CategoryName)"/>

        <resource name="supply_item_category">
            <xsl:attribute name="tuid">
                <xsl:value-of select="$CategoryID"/>
            </xsl:attribute>
            <data field="code"><xsl:value-of select="substring($CategoryName,1,16)"/></data>
            <data field="name"><xsl:value-of select="$CategoryName"/></data>
            <reference field="catalog_id" resource="supply_catalog">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="$CatalogName"/>
                </xsl:attribute>
            </reference>
            <data field="can_be_asset" value="true">True</data>
        </resource>

    </xsl:template>

    <!-- ****************************************************************** -->
    <xsl:template name="SupplyItem">

        <xsl:variable name="CatalogName" select="col[@field='Catalog']/text()"/>
        <xsl:variable name="CategoryName" select="col[@field='Category']/text()"/>
        <xsl:variable name="CategoryID" select="concat($CatalogName, '|', $CategoryName)"/>
        <xsl:variable name="BrandName" select="col[@field='Brand']/text()"/>
        <xsl:variable name="ItemCode" select="concat(col[@field='Name'], ', ',
                                                     col[@field='Model'], ', ',
                                                     col[@field='Brand'])"/>
        <xsl:variable name="Name" select="col[@field='Name']/text()"/>
        <xsl:variable name="Model" select="col[@field='Model']/text()"/>

        <resource name="supply_item">
            <xsl:attribute name="tuid">
                <xsl:value-of select="$ItemCode"/>
            </xsl:attribute>
            <data field="name"><xsl:value-of select="$Name"/></data>
            <data field="model"><xsl:value-of select="$Model"/></data>
            <data field="um">piece</data>
            <!-- Link to Supply Catalog -->
            <reference field="catalog_id" resource="supply_catalog">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="$CatalogName"/>
                </xsl:attribute>
            </reference>
            <!-- Link to Supply Item Category -->
            <reference field="item_category_id" resource="supply_item_category">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="$CategoryID"/>
                </xsl:attribute>
            </reference>
            <xsl:if test="$BrandName!=''">
                <reference field="brand_id" resource="supply_brand">
                    <xsl:attribute name="tuid">
                        <xsl:value-of select="$BrandName"/>
                    </xsl:attribute>
                </reference>
            </xsl:if>
            <!-- Nest to Supply Catalog -->
            <resource name="supply_catalog_item">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="$ItemCode"/>
                </xsl:attribute>
                <!-- Link to Supply Catalog -->
                <reference field="catalog_id" resource="supply_catalog">
                    <xsl:attribute name="tuid">
                        <xsl:value-of select="$CatalogName"/>
                    </xsl:attribute>
                </reference>
                <!-- Link to Supply Item Category -->
                <reference field="item_category_id" resource="supply_item_category">
                    <xsl:attribute name="tuid">
                        <xsl:value-of select="$CategoryID"/>
                    </xsl:attribute>
                </reference>
            </resource>
        </resource>

    </xsl:template>

    <!-- ****************************************************************** -->
    <xsl:template name="Person">
        <xsl:variable name="PersonName" select="col[@field='Assigned To']/text()"/>

        <xsl:if test="$PersonName!=''">
            <resource name="pr_person">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="$PersonName"/>
                </xsl:attribute>
                <!-- @todo: use a pattern like "LastName, FirstName" instead of just
                            first name in order to do proper de-duplication
                -->
                <data field="first_name"><xsl:value-of select="$PersonName"/></data>
            </resource>
        </xsl:if>

    </xsl:template>

    <!-- ****************************************************************** -->
    <xsl:template name="Room">
        <xsl:variable name="OrgName" select="col[@field='Organisation']/text()"/>
        <xsl:variable name="OfficeName" select="col[@field='Office']/text()"/>
        <xsl:variable name="OfficeID" select="concat($OrgName, '|', $OfficeName)"/>
        <xsl:variable name="RoomName" select="col[@field='Room']/text()"/>
        <xsl:variable name="RoomID" select="concat($OrgName, '|', $OfficeName, '|', $RoomName)"/>

        <xsl:if test="$RoomName!=''">
            <resource name="org_room">
                <xsl:attribute name="tuid">
                    <xsl:value-of select="$RoomID"/>
                </xsl:attribute>
                <data field="name"><xsl:value-of select="$RoomName"/></data>
                <reference field="site_id" resource="org_office">
                    <xsl:attribute name="tuid">
                        <xsl:value-of select="$OfficeID"/>
                    </xsl:attribute>
                </reference>
            </resource>
        </xsl:if>

    </xsl:template>

    <!-- ****************************************************************** -->

</xsl:stylesheet>
