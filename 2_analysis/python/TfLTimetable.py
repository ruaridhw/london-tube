#' ---
#' title: "TfL Timetable"
#' author: "Ruaridh Williamson"
#' ---

#' This file provides a custom class for parsing the
#' UK Department for Transport TransXChange schema used
#' across the country for representing train, bus, ferry,
#' tube and light rail timetable data.
#'
#' The logic provided here has been tested on the tube
#' timetables only however the schema is identical across
#' transport modes and should be highly portable.
#'
#' To see how to call this class see the `Main()` function 
#' in [XMLParsing.py](XMLParsing.html).
#'
#' # Class
#'
#' The class is based on the ElementTree object and is
#' initialised from the file path to an XML timetable file.
#'
#' It contains a number of methods for parsing data, the primary
#' interface being `get_df` which calls the other methods
#' as required.
#'
#' The final part of the class defines the XPaths to various
#' data points found in the timetable. Not every data point in
#' every timetable has been defined so these can be added
#' if necessary.
#'
#' [Source code](https://github.com/ruaridhw/london-tube/blob/master/2_analysis/python/TfLTimetable.py)

#+ tlftimetable_class, engine='python'
import pandas as pd
from lxml import etree

_DEBUG_ = False

class TfLTimetable(etree._ElementTree):
    # Define TransXChange schema namespace
    ns = {'txc': 'http://www.transxchange.org.uk/'}
    
    def __init__(self, file):
        """
            Initialise as an ElementTree object from the
            path to a TransXChange Timetable XML file
        """
        self.parse(file)
        
#' ## Methods

    def get_xpath(self, path):
        """
            path   An XPath
            
            Simple wrapper for xpath method that includes
            the required TransXChange namespace
            
            Returns a list of all XPath matches
        """
        return self.xpath(path, namespaces=self.ns)
    
    def get_tag(self, e):
        """
            e      An lxml node element
            
            Simple wrapper for returning a tag name
            without the namespace information
            
            Returns the tag name as a string
        """
        return e.tag.lstrip('{'+self.ns['txc']+'}')

    def get_varying_child_tags(self, path):
        """
            path    The XPath to an Operating Profile node.
                    See TfLTimetable.op_prof_paths
            
            These nodes contain a varying number of nested child tags
            so it is necessary to extract the tag names of each
            tag that is present and match it to an id_value found
            in a specific parent tag (defined for each type of XPath;
            VehicleJourney or Service).
            
            Returns a dictionary of DataFrames where each item is a
            particular profile (RegularDayType, BankHolidayOperation, ...)
            Each DataFrame contains two columns: the id_value repetitively
            listed against each child tag found for that id.
        """

        tables = {}
        colnames = {}
        for e in self.get_xpath(path):

            id_parent = e.getparent().getparent()

            # Extract the relevant id to store the extracted child tags against
            if 'VehicleJourney' in id_parent.tag:
                id_value = id_parent[3].text # VehicleJourneyCode is the 4th node of the parent
                category = 'VehicleJourneys'
            elif 'Service' in id_parent.tag:
                id_value = id_parent[0].text # ServiceCode is the 1st node of the parent
                category = 'Services'
            else:
                raise ValueError('This XPath is not yet supported')

            if _DEBUG_: print(id_value)

            # Loop through the types of profiles (RegularDayType, BankHolidayOperation, ...)
            # creating a new table and column names for each
            for profile in e:
                tablename = category + '_' + self.get_tag(profile.getparent()) + '_' + \
                    self.get_tag(profile)
                colnames[tablename] = [category, self.get_tag(profile)]

                if _DEBUG_: print(col_name)

                # Loop through the child tags extracting out the tag name and adding
                # it to the newly created table
                for child in profile.iterchildren():
                    cell_value = self.get_tag(child)

                    if tablename not in tables:
                        tables[tablename] = [(id_value, cell_value)]
                    else:
                        tables[tablename].append((id_value, cell_value))

                    if _DEBUG_: print(cell_value)

        # Store DataFrame in dictionary keyed by tablename
        for tablename, data in tables.items():
            tables[tablename] = pd.DataFrame.from_records(data, columns = colnames[tablename])

        return tables

    def get_occasional_child_node(self, path):
        """
            path    The XPath to a node that is sometimes missing
            
            This function is called if a tilde is found in the
            XPath. Though not a valid XPath character it is used here
            to signify a call to this function and then removed.
            
            An example of an occasional child node is the WaitTime
            at a station. If a train has no WaitTime at a station then
            the node does not appear so this function handles the XPath
            not necessarily existing.
            
            This has to be extracted manually because etree.xpath returns
            a list of results so there is no way to match the missing values
            back to their ids otherwise.
            
            Returns a list of extracted values equal in length to the
            number of matches of path_parent (and therefore does not squash
            missing values).
        """
        path_parent, path_child = path.split('~')
        col = []
        for node in self.get_xpath(path_parent):
            val = node.xpath(path_child, namespaces=self.ns)
            # val is a list with only ever 0 or one elements
            col.append(val[0] if len(val) > 0 else None)
        return col

    def get_df(self, dict_of_paths):
        """
            dict_of_paths    A dictionary of XPaths all corresponding
                             to a single table and should therefore be
                             equal in the number of returned rows for
                             each path.
                             See TfLTimetable.NptgLocalities et al.
            
            Dispatches Case 1, 2 or 3 depending on any special characters
            foun in the incumbent XPath.
            
            Returns a single dataframe where each column corresponds to
            the keys of dict_of_paths
        """
        cols = []
        for var, path in dict_of_paths.items():
            
            # Case 1: Tag may or may not exist.
            #         ~ is not a valid XPath character but is used to manually
            #         indicate a call to Case 1
            if '~' in path:
                cols.append((var, self.get_occasional_child_node(path)))
            
            # Case 2: Return a column for the id attribute of the parent node
            #         with the same length as the number of siblings.
            #         parent::node() is not a valid XPath expression in this context
            #         but is used to manually indicate a call to Case 2
            elif path.endswith('parent::node()'):
                nodes = self.get_xpath(path.rstrip('/parent::node()'))
                cols.append((var, [node.getparent().get('id') for node in nodes]))
            
            # Case 3: Return a column for XPath values
            else:
                cols.append((var, self.get_xpath(path)))
            
        df = pd.DataFrame.from_items(cols)
        return df

#' ## XPaths
#'
#' Contains the XPath definitions of the columns for each table within a
#' TransXChange XML file. Currently omits tables and columns which are
#' not relevant to London Underground timetables
    
    # NptgLocalities
    root_localities = "./txc:NptgLocalities/txc:AnnotatedNptgLocalityRef"
    NptgLocalities = {
        "NptgLocalityRef": root_localities + "/txc:NptgLocalityRef/text()",
        "LocalityName": root_localities + "/txc:LocalityName/text()"
    }

    # StopPoints
    root_stops = "./txc:StopPoints/txc:StopPoint"
    StopPoints = {
        "AtcoCode": root_stops + "/txc:AtcoCode/text()",
        "Descriptor_CommonName": root_stops + "/txc:Descriptor/txc:CommonName/text()",
        "Place_NptgLocalityRef": root_stops + "/txc:Place/txc:NptgLocalityRef/text()",
        "Place_Location_Easting": root_stops + "/txc:Place/txc:Location/txc:Easting/text()",
        "Place_Location_Northing": root_stops + "/txc:Place/txc:Location/txc:Northing/text()",
    }

    # RouteSections and RouteLinks
    root_routelinks = "./txc:RouteSections/txc:RouteSection/txc:RouteLink"
    RouteLinks = {
        "RouteSections": root_routelinks + "/parent::node()",
        "RouteLink": root_routelinks + "/@id",
        "From_StopPointRef": root_routelinks + "/txc:From/txc:StopPointRef/text()",
        "To_StopPointRef": root_routelinks + "/txc:To/txc:StopPointRef/text()",
        "Distance": root_routelinks + "~txc:Distance/text()",
        "Direction": root_routelinks + "/txc:Direction/text()",
    }

    # Routes
    root_routes = "./txc:Routes/txc:Route"
    Routes = {
        "Route": root_routes + "/@id",
        "Description": root_routes + "/txc:Description/text()",
        "RouteSectionRef": root_routes + "/txc:RouteSectionRef/text()",
    }

    # JourneyPatternSections and JourneyPatternTimingLink
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
        "WaitTime": root_journeysections + "/txc:To~txc:WaitTime/text()", # invalid xpath, used to distinguish from generic node
    }

    # Services
    root_services = "./txc:Services/txc:Service"
    Services = {
        "ServiceCode": root_services + "/txc:ServiceCode/text()",
        "Line": root_services + "/txc:Lines/txc:Line/@id",
        "LineName": root_services + "/txc:Lines/txc:Line/txc:LineName/text()",
        "OpPeriod_StartDate": root_services + "/txc:OperatingPeriod/txc:StartDate/text()",
        "OpPeriod_EndDate": root_services + "/txc:OperatingPeriod/txc:EndDate/text()",
        #"OpProf_DaysOfWeek": root_services + "/txc:OperatingProfile/txc:RegularDayType/txc:DaysOfWeek",
        #"OpProf_Hol_DayofOp": root_services + "/txc:OperatingProfile/txc:BankHolidayOperation/txc:DaysOfOperation",
        #"OpProf_Hol_DayofNonOp": root_services + "/txc:OperatingProfile/txc:BankHolidayOperation/txc:DaysOfNonOperation",
        "Description": root_services + "/txc:Description/text()",
        "StandardService_Origin": root_services + "/txc:StandardService/txc:Origin/text()",
        "StandardService_Destination": root_services + "/txc:StandardService/txc:Destination/text()",
    }
    ServicesOpProf = {
        "ServiceCode": root_services + "/txc:ServiceCode/text()",
        "OpProf_DaysOfWeek": root_services + "/txc:OperatingProfile/txc:RegularDayType/txc:DaysOfWeek",
        "OpProf_Hol_DayofOp": root_services + "/txc:OperatingProfile/txc:BankHolidayOperation/txc:DaysOfOperation",
        "OpProf_Hol_DayofNonOp": root_services + "/txc:OperatingProfile/txc:BankHolidayOperation/txc:DaysOfNonOperation",
    }

    # JourneyPatterns
    root_journeypatterns = "./txc:Services/txc:Service/txc:StandardService/txc:JourneyPattern"
    JourneyPatterns = {
        "JourneyPattern": root_journeypatterns + "/@id",
        "Direction": root_journeypatterns + "/txc:Direction/text()",
        "RouteRef": root_journeypatterns + "/txc:RouteRef/text()",
        "JourneyPatternSectionRefs": root_journeypatterns + "/txc:JourneyPatternSectionRefs/text()",
    }

    # VehicleJourneys
    root_vehiclejourneys = "./txc:VehicleJourneys/txc:VehicleJourney"
    VehicleJourneys = {
        "PrivateCode": root_vehiclejourneys + "/txc:PrivateCode/text()",
        #"OpProf_DaysOfWeek": root_vehiclejourneys + "/txc:OperatingProfile/txc:RegularDayType/txc:DaysOfWeek",
        "VehicleJourneyCode": root_vehiclejourneys + "/txc:VehicleJourneyCode/text()",
        "ServiceRef": root_vehiclejourneys + "/txc:ServiceRef/text()",
        "LineRef": root_vehiclejourneys + "/txc:LineRef/text()",
        "JourneyPatternRef": root_vehiclejourneys + "/txc:JourneyPatternRef/text()",
        "DepartureTime": root_vehiclejourneys + "/txc:DepartureTime/text()",
    }
    VehicleJourneysOpProf = {
        "VehicleJourneyCode": root_vehiclejourneys + "/txc:VehicleJourneyCode/text()",
        "OpProf_DaysOfWeek": root_vehiclejourneys + "/txc:OperatingProfile/txc:RegularDayType/txc:DaysOfWeek",
    }

#' Dictionary collating all tables' XPaths together

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

#' Defines the Operating Profile XPaths which require scraping via `get_varying_child_tags`
#' rather than `get_df` as per all other XPaths.

    op_prof_paths = [
                "./txc:VehicleJourneys/txc:VehicleJourney/txc:OperatingProfile/*",
                "./txc:Services/txc:Service/txc:OperatingProfile/*"
            ]
