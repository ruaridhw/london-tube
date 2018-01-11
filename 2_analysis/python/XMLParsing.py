#' ---
#' title: "XML Parsing"
#' author: "Ruaridh Williamson"
#' ---

#' This script contains a "main" function which implements the Class TfLTimetable
#' found [here](TfLTimetable.html) in preference to the R methodology
#' illustrated in the "Managing Data" notebook.
#'
#' The reason for this is the `lxml` library is significantly more
#' performant and versatile for extracting the non-standard XML data from
#' various nested nodes, attributes and varying tags.
#'
#' # Main method
#'
#' 1. Iterate over all the files for a given tube line
#' 2. Scrape all the relevant data frames
#' 3. Store them in a nested dictionary indexed by table and file
#' 4. Output data frames into a common Line file for each table.
#'
#' The Operating Period and Profile information is scraped separately
#' from the `TfLTimetable.get_df` function due to the extra level of
#' sophistication required.
#' These nodes contain a varying number of child nodes where the data is
#' contained in the tag name (rather than the tag text) and the tag name
#' is not known in advance.
#'
#' Due to the fact that the **StopPoints** and **NptgLocalities**
#' tables are the only two that contain duplicate information *across*
#' tube lines, these are held in memory throughout the iteration in
#' `output_tables_common` without being written to disk after each line
#' and dumped to a single file with the prefix "ALL" in place of the line code.
#'
#' To enable efficient transition between Python and R, the DFs are
#' serialised into the Feather format.
#'
#' [Source code](https://github.com/ruaridhw/london-tube/blob/master/2_analysis/python/XMLParsing.py)

#+ xmlparsing, engine='python'
import click
@click.command()
@click.argument('input_dir', required=1, type=click.Path(exists=True))
@click.argument('output_dir', required=1, type=click.Path(exists=True))
def main(input_dir, output_dir):
    """
        This script is used for extracting the full set of features from the
        TransXChange timetable data.

        This function calls a number of functions defined in a custom
        TfLTimetable Class based on the lxml ElementTree.
        For that Class definition see TfLTimetable.py.

        This source file is invoked with two arguments:

            input:    The location of the XML files for parsing. eg ../1_data/1_1_raw_data/timetables/data

            output:   The location to output the resulting tidy Feather dataframes. eg ../1_data/1_2_processed_data

        `$python3 python/XMLParsing.py ../1_data/1_1_raw_data/timetables/data ../1_data/1_2_processed_data`

        The TfLTimetable module must be in the local path or otherwise installed.
    """
    import os
    import re

    import feather
    import pandas as pd

    import TfLTimetable as tfl

    data_dir_input = input_dir
    data_dir_output = output_dir

    files_all_lines = os.listdir(data_dir_input)

    # Pattern match all possible three letter abbreviations of tube lines
    lines = []
    for file in files_all_lines:
        extracted_line = re.search("tfl_1-([A-Z]{3})[^.]+\.xml", file)
        if extracted_line is not None and len(extracted_line.group(1)) > 0:
            lines.append(extracted_line.group(1))
    lines = list(set(lines))

    output_tables_common = {}
    for i, line in enumerate(lines):
        print('---- Scraping Line {} of {}: {}'.format(i + 1, len(lines), line))
        # Filter to specific tube line
        this_line_pattern = "tfl_1-{}[^.]+\.xml".format(line)
        # Retrieve the full path of all xml files which match `this_line_pattern`
        this_line_files = []
        for file in files_all_lines:
            if re.match(this_line_pattern, file) is not None:
                this_line_files.append(os.path.join(data_dir_input, file))

        # Build nested dictionary with the structure
        # {tablename: xml_file: pd.DataFrame}
        output_tables = {}
        for j, file in enumerate(this_line_files):
            file_sans_path = os.path.basename(file)
            print('     ---- File {} of {}: {}'.format(j + 1,
                                                len(this_line_files), file_sans_path))
            timetable = tfl.TfLTimetable(file)
            for table, paths in timetable.required_xpaths.items():
                if table == "NptgLocalities" or table == "StopPoints":
                    if table not in output_tables_common:
                        output_tables_common[table] = timetable.get_df(paths)
                    else:
                        df = pd.concat([output_tables_common[table],
                                        timetable.get_df(paths)],
                                       axis=0)
                        output_tables_common[table] = df.drop_duplicates()
                else:
                    if table not in output_tables:
                        output_tables[table] = {file_sans_path: timetable.get_df(paths)}
                    else:
                        output_tables[table][file_sans_path] = timetable.get_df(paths)

            # Parse Operating Periods for VehicleJourneys and Services
            for op_prof_path in timetable.op_prof_paths:
                op_prof_tables = timetable.get_varying_child_tags(op_prof_path)

                for table, data in op_prof_tables.items():
                    if table not in output_tables:
                        output_tables[table] = {file_sans_path: data}
                    else:
                        output_tables[table][file_sans_path] = data

        # Concatenate tables across XML files and dump to a Feather file
        print('     Dumping tables to output directory: {}'.format(data_dir_output))
        for tablename, files in output_tables.items():
            df = pd.concat(files, axis=0)
            df.drop_duplicates(inplace=True)
            feather.write_dataframe(df, data_dir_output + "/" + line + "-" +
                                    tablename + ".feather")

    print('Dumping common tables to output directory: {}'.format(data_dir_output))
    line = "ALL"
    for tablename, df in output_tables_common.items():
        feather.write_dataframe(df, data_dir_output + "/" + line + "-" +
                                tablename + ".feather")

if __name__ == '__main__':
    main()
