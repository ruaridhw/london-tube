#######################################################
################## PARSING FUNCTIONS ##################
#######################################################

def get_xpath(doc, path):
    return doc.xpath(path, namespaces={'txc': 'http://www.transxchange.org.uk/'})

def get_xpath_child_tags(doc, var, path):
    # Build a dictionary of all possible child tags mapped
    # to an empty list to populate later
    all_tags = []
    for e in get_xpath(doc, path + "/child::node()"):
        if etree.iselement(e):
            all_tags.append(e.tag.strip('{'+ns['txc']+'}'))
    all_tags = list(set(all_tags))
    all_tags_dict = {var + "__" + tag: [] for tag in all_tags}

    # Loop through all nodes and add an entry to
    # the dict's corresponding list depending on whether
    # the list item is a child tag of the node or not
    for e in get_xpath(doc, path):
        out = []
        for child in e.iterchildren():
            out.append(child.tag.strip('{'+ns['txc']+'}'))
        for col in all_tags_dict.keys():
            all_tags_dict[col].append(True if col.lstrip(var + "__") in out else False)

    return all_tags_dict

def get_df(doc, dict_of_paths):
    cols = []
    for var, path in dict_of_paths.items():
        # Case 1: Return several columns for the existance of each subtag in a path
        if var.startswith('OpProf'):
            for each_var, col in get_xpath_child_tags(doc, var, path).items():
                cols.append((each_var, col))
        # Case 2: Return a column for the id attribute of the parent node
        #         with the same length as the number of siblings
        elif path.endswith('parent::node()'):
            nodes = get_xpath(doc, path.rstrip('/parent::node()'))
            cols.append((var, [node.getparent().get('id') for node in nodes]))
        # Case 3: Return a column for XPath values
        else:
            cols.append((var, get_xpath(doc, path)))
    df = pd.DataFrame.from_items(cols)
    return df

#######################################################
######################## XPATHS #######################
#######################################################

## NptgLocalities
root_localities = "./txc:NptgLocalities/txc:AnnotatedNptgLocalityRef"
NptgLocalities = {
    "NptgLocalityRef": root_localities + "/txc:NptgLocalityRef/text()",
    "LocalityName": root_localities + "/txc:LocalityName/text()"
}

## StopPoints
root_stops = "./txc:StopPoints/txc:StopPoint"
StopPoints = {
    "AtcoCode": root_stops + "/txc:AtcoCode/text()",
    "Descriptor_CommonName": root_stops + "/txc:Descriptor/txc:CommonName/text()",
    "Place_NptgLocalityRef": root_stops + "/txc:Place/txc:NptgLocalityRef/text()",
    "Place_Location_Easting": root_stops + "/txc:Place/txc:Location/txc:Easting/text()",
    "Place_Location_Northing": root_stops + "/txc:Place/txc:Location/txc:Northing/text()",
}

## RouteSections
## RouteLinks
root_routelinks = "./txc:RouteSections/txc:RouteSection/txc:RouteLink"
RouteLinks = {
    "RouteSections": root_routelinks + "/parent::node()",
    "RouteLink": root_routelinks + "/@id",
    "From_StopPointRef": root_routelinks + "/txc:From/txc:StopPointRef/text()",
    "To_StopPointRef": root_routelinks + "/txc:To/txc:StopPointRef/text()",
    #"Distance": root_routelinks + "/txc:Distance/text()", ## Uneven node lengths in 'tfl_1-BAK-_-y05-1462422.xml'
    "Direction": root_routelinks + "/txc:Direction/text()",
}

## Routes
root_routes = "./txc:Routes/txc:Route"
Routes = {
    "Route": root_routes + "/@id",
    "Description": root_routes + "/txc:Description/text()",
    "RouteSectionRef": root_routes + "/txc:RouteSectionRef/text()",
}

## JourneyPatternSections
## JourneyPatternTimingLink
root_journeysections = "./txc:JourneyPatternSections/txc:JourneyPatternSection/txc:JourneyPatternTimingLink"
JourneyPatternTimingLinks = {
    "JourneyPatternSections": root_journeysections + "/parent::node()",
    "JourneyPatternTimingLink": root_journeysections + "/@id",
    "From_SequenceNumber": root_journeysections + "/txc:From/@SequenceNumber",
    "From_Activity": root_journeysections + "/txc:From/txc:Activity/text()",
    "From_StopPointRef": root_journeysections + "/txc:From/txc:StopPointRef/text()",
    "To_SequenceNumber": root_journeysections + "/txc:To/@SequenceNumber",
    "To_Activity": root_journeysections + "/txc:To/txc:Activity/text()",
    "To_StopPointRef": root_journeysections + "/txc:To/txc:StopPointRef/text()",
    "RouteLinkRef": root_journeysections + "/txc:RouteLinkRef/text()",
    "RunTime": root_journeysections + "/txc:RunTime/text()",
}

## Services
root_services = "./txc:Services/txc:Service"
Services = {
    "ServiceCode": root_services + "/txc:ServiceCode/text()",
    "Line": root_services + "/txc:Lines/txc:Line/@id",
    "LineName": root_services + "/txc:Lines/txc:Line/txc:LineName/text()",
    "OpPeriod_StartDate": root_services + "/txc:OperatingPeriod/txc:StartDate/text()",
    "OpPeriod_EndDate": root_services + "/txc:OperatingPeriod/txc:EndDate/text()",
    "OpProf_DaysOfWeek": root_services + "/txc:OperatingProfile/txc:RegularDayType/txc:DaysOfWeek",
    "OpProf_Hol_DayofOp": root_services + "/txc:OperatingProfile/txc:BankHolidayOperation/txc:DaysOfOperation",
    "OpProf_Hol_DayofNonOp": root_services + "/txc:OperatingProfile/txc:BankHolidayOperation/txc:DaysOfNonOperation",
    "Description": root_services + "/txc:Description/text()",
    "StandardService_Origin": root_services + "/txc:StandardService/txc:Origin/text()",
    "StandardService_Destination": root_services + "/txc:StandardService/txc:Destination/text()",
}

## JourneyPatterns
root_journeypatterns = "./txc:Services/txc:Service/txc:StandardService/txc:JourneyPattern"
JourneyPatterns = {
    "JourneyPattern": root_journeypatterns + "/@id",
    "Direction": root_journeypatterns + "/txc:Direction/text()",
    "RouteRef": root_journeypatterns + "/txc:RouteRef/text()",
    "JourneyPatternSectionRefs": root_journeypatterns + "/txc:JourneyPatternSectionRefs/text()",
}

## VehicleJourneys
root_vehiclejourneys = "./txc:VehicleJourneys/txc:VehicleJourney"
VehicleJourneys = {
    "PrivateCode": root_vehiclejourneys + "/txc:PrivateCode/text()",
    "OpProf_DaysOfWeek": root_vehiclejourneys + "/txc:OperatingProfile/txc:RegularDayType/txc:DaysOfWeek",
    "VehicleJourneyCode": root_vehiclejourneys + "/txc:VehicleJourneyCode/text()",
    "ServiceRef": root_vehiclejourneys + "/txc:ServiceRef/text()",
    "LineRef": root_vehiclejourneys + "/txc:LineRef/text()",
    "JourneyPatternRef": root_vehiclejourneys + "/txc:JourneyPatternRef/text()",
    "DepartureTime": root_vehiclejourneys + "/txc:DepartureTime/text()",
}

required_xpaths = {
    "NptgLocalities": NptgLocalities,
    "StopPoints": StopPoints,
    "RouteLinks": RouteLinks,
    "Routes": Routes,
    "JourneyPatternTimingLinks": JourneyPatternTimingLinks,
    "Services": Services,
    "JourneyPatterns": JourneyPatterns,
    "VehicleJourneys": VehicleJourneys
}

if __name__ == '__main__':
    import os
    import re
    import pandas as pd
    from lxml import etree
    import feather

    data_dir_input = "0_raw_data/timetables/data"
    data_dir_output = "1_scraped_data"

    files_all_lines = os.listdir(data_dir_input)

    # Pattern match all possible three letter abbreviations of tube lines
    lines = []
    for file in files_all_lines:
        extracted_line = re.search("tfl_1-([A-Z]{3})[^.]+\.xml", file)
        if extracted_line is not None and len(extracted_line.group(1)) > 0:
            lines.append(extracted_line.group(1))
    lines = list(set(lines)) # Distinct list

    for i, line in enumerate(lines):
        print('---- Scraping Tube Line {} of {}: {}'.format(i + 1, len(lines), line))
        # Filter to specific tube line
        this_line_pattern = "tfl_1-{}[^.]+\.xml".format(line)
        # Retrieve the full path of all xml files which match `this_line_pattern`
        this_line_files = [os.path.join(data_dir_input, file) for file in files_all_lines if re.match(this_line_pattern, file) is not None]

        # Build nested dictionary with the structure
        # {tablename: xml_file: pd.DataFrame}
        tfl = {}
        for j, file in enumerate(this_line_files):
            file_sans_path = os.path.basename(file)
            print('     ---- File {} of {}: {}'.format(j + 1, len(this_line_files), file_sans_path))
            doc = etree.parse(file)
            for table, paths in required_xpaths.items():
                if table not in tfl:
                    tfl[table] = {file_sans_path: get_df(doc, paths)}
                else:
                    tfl[table][file_sans_path] = get_df(doc, paths)

        # Concatenate tables across XML files and dump to a Feather file
        print('     Dumping tables to output directory: {}'.format(data_dir_output))
        for tablename, files in tfl.items():
            df = pd.concat(files, axis=0)
            df.drop_duplicates(inplace=True)
            feather.write_dataframe(df, data_dir_output + "/" + line + "-" + tablename + ".feather")
