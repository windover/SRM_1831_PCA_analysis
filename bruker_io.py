# -*- coding: utf-8 -*-
"""
.. module:: bruker_io
   :platform: Windows
   :synopsis: input, output, and conversion of Bruker XRF spectra files

.. moduleauthor:: Donald Windover (windover@nist.gov)

Created on Fri Apr 26 09:49:43 2019

"""
#

############################
#  20190426 Donald Windover
#
#  These are are series of functions used to read in data from the Bruker M4
#  and to allow editing of the spectrum contained in the file.  They also
#  us to read in fitting information, and write out to a txt format similar
#  to the Bruker .txt conversion as well as the .msa file format
#
#  we use these functions to read in data for analysis in later packages
#
###########################
#
import xml.etree.ElementTree as ET
import re as re
from datetime import datetime
import numpy as np


class FittingData:
    """ all parameters imported or exported from Bruker Spectra Files

    def __init__(self, file_name):

        **self.file_name:** str [?]
            file to be read (alwyas input for an instance)

    **calibration_abs:** float [-955.1]
        set value for zero of Bruker M4 at 40keV setting

    **calibration_lin:** float [10]
        set value for linerarity of Bruker M4 spectr at 40keV setting

    **channels:** np.array [4096,]
        assuming 4096 MCA channels (Bruker m4)  EDAX uses 4000 instead

    **data_lines:** str [""]
        dummy string for the parsed lines of an ascii readable file

    **date_measure:** str [""]
        date read from Bruker M4 .spx files by ETREE

    **detector_thickness:** float [0]
        dector thickness in um

    **detector_type:** str [""]
        detector type from Bruker M4 .spx

    **energy_scale:** np.array [4096,]
        numpy array of 4096 energy spectra scalings  (initialized as zeros)

    **file_content:** str [""]
        entire asci file read for import of data

    **file_line:** str ['']
        the current single line of a data file

    **file_lines:** list of str ['']
        python list of strings; each list being a line of an imported file

    **file_status:** bool [False]
        this boolean is used in test of .txt file = Bruker spectra

    **header_lines:** list of str ['']
        lines preceding the start of spectra data in import file

    **life_time_in_ms:** int [0]
        live time for MCA spectra collection

    **line_count:** int [0]
        dummy variable used in counting for start of spectra data

    **mn_fwhm:** float [143.796]
        manganese fwhm in eV for the detector used in spectra collection

    **modification:** str ['_modified.txt']
        name to be appended to .txt files after modified by functions

    **no_channels:** int [4096]
        number of channels in MCA default to Bruker value

    **pulse_density:** str ['']
        left as a string, as we are not using this for any calc

    **real_time_in_ms:** int [0]
        real time for MCA spectra collection

    **replace_lines:** list of str []
        list of string lines containing modified spectra data

    **shaping_time:** float [0]
        detector countr rate shpaing time
        
    **si_dead_layer:** float [0]
        dead layer of detector used in modeling quantitative data

    **start_count:** int [21]
        line directly after header info in spectra file (start of spectra)

    **time_measure:** str ['']
        time read from Bruker M4 .spx files by ETREE

    **window_type:** str ['']
        material used in detector (used in quant modeling)

    """

    def __init__(self, file_name):
        """ name of spectrum file imported or exported"""
        self.file_name = file_name
    calibration_abs = -955.1
    calibration_lin = 10
    channels = np.zeros(4096)
    data_lines = ''
    date_measure = ''
    detector_thickness = 0
    detector_type = '' #
    energy_scale = np.zeros(4096)
    file_content = ''
    file_line = ''
    file_lines = ''
    file_status = False
    header_lines = ''
    life_time_in_ms = 0
    line_count = 0
    mn_fwhm = 143.796
    modification = '_modified.txt'
    no_channels = 0
    pulse_density = ''
    real_time_in_ms = 0
    replace_lines = []
    shaping_time = 0
    si_dead_layer = ''
    start_count = 21
    time_measure = ''
    window_type = ''


###########################
#  20190426 Donald Windover
#  This function tests if a .txt file present in the directory is a Bruker
#  spectrum txt file by reading the first line and comparing to expected value
#
def bruker_txt_test(fittingdata):
    """ Function to test if *.txt* is a Bruker spectra file

    We test if it is a Bruker *.txt* file by reading the first line and
    comparing the result against the known header line from the Bruker txt
    files (see the following line of code:)

    Parameters
    ----------
    
    fittingdata : see Class FittingData
    
    
    Example
    -------
    
    >>>> fittingdata.file_status = bool(r'Bruker Nano GmbH Berlin, Germany\\n'
    >>>>                                in fittingdata.file_lines[0]) 
    
    See Also
    --------
    
    FittingData
    
    """
#    .. code-block:: python
#
#        fittingdata.file_status = bool(r'Bruker Nano GmbH Berlin, Germany\\n'
#                                       in fittingdata.file_lines[0]) """Build and fit a model of an EDS Signal1D.
#
    fittingdata.file_content = open(fittingdata.file_name)
    fittingdata.file_lines = fittingdata.file_content.readlines()
    fittingdata.file_content.close()
    fittingdata.file_status = bool('Bruker Nano GmbH Berlin, Germany\n'
                                   in fittingdata.file_lines[0])
    fittingdata.file_content = ''
    fittingdata.file_lines = ''
    return

###########################
#  20190426 Donald Windover
#  This function reads in the .txt file to provide data for fitting routines
#
def bruker_txt_import(fittingdata):
    """ Function to import the bruker *.txt* spectra data

    The working portion of this import breaks the 2 column (energy,counts)
    spectral data into two numpy arrays via an inefficient *for* loop:

    .. code-block:: python

        fittingdata.energy_scale[i] = np.float(split_line[0])
        fittingdata.channels[i] = np.float(split_line[1])

    """
    #open Bruker txt file
    #print(txt_file)
    fittingdata.file_content = open(fittingdata.file_name)
    fittingdata.file_lines = fittingdata.file_content.readlines()
    fittingdata.file_content.close()
    #count the line where energy, counts data begins
    fittingdata.line_count = 0
    for fittingdata.file_line in fittingdata.file_lines:  # finds the start of the error data
        fittingdata.line_count = fittingdata.line_count + 1
        if fittingdata.file_line.find('Counts') != -1:  #looks for the word 'Counts' in each line
            start_count = fittingdata.line_count
            if fittingdata.start_count != start_count:
                print('warning: start of channels != normal value')
                fittingdata.start_count = start_count
    fittingdata.data_lines = fittingdata.file_lines[fittingdata.start_count:]
    #keeps only the lines of spectral data
    fittingdata.energy_scale = np.zeros(len(fittingdata.data_lines))
    fittingdata.channels = np.zeros(len(fittingdata.data_lines))
    for i in np.arange(len(fittingdata.data_lines)):
        fittingdata.file_line = fittingdata.data_lines[i]
        split_line = fittingdata.file_line.split()
        fittingdata.energy_scale[i] = np.float(split_line[0])
        fittingdata.channels[i] = np.float(split_line[1])
    #provides 2 1D arrays with the energy and counts data
    print('import size: ', fittingdata.channels.shape)
    fittingdata.file_content = ''
    fittingdata.file_lines = ''
    fittingdata.file_line = ''
    fittingdata.data_lines = ''
    return #these counts have been pulse pile up modified


###########################
#  20190426 Donald Windover
#  This function reads in the .txt file, passes the channels and energy
#  for modification, and then resaves channels with a "modified" name change
#
def bruker_txt_mod(fittingdata):
    """ function to export a Bruker *.txt* with modified spectra data

    This function opens the Bruker *.txt* file, separates the header data
    from the spectra data section, and rewrites the content of the spectra
    section from *energy_scale* and *channels* currently in the fittingdata
    instance.  The data is then recombined and saved under a new name
    combined from the original plus the *modification* string.

    """
    print('size into string on export: ', fittingdata.channels.shape)
    fittingdata.file_content = open(fittingdata.file_name)
    fittingdata.file_lines = fittingdata.file_content.readlines()
    fittingdata.file_content.close()
    fittingdata.line_count = 0
    for fittingdata.file_line in fittingdata.file_lines:
        # finds the start of the error data
        fittingdata.line_count = fittingdata.line_count +1
        if fittingdata.file_line.find('Counts') != -1:
            #looks for the word 'Counts' in each line
            start_count = fittingdata.line_count
            if fittingdata.start_count != start_count:
                print('warning: start of channels != normal value')
                fittingdata.start_count = start_count
    fittingdata.header_lines = fittingdata.file_lines[:fittingdata.start_count]
    fittingdata.data_lines = fittingdata.file_lines[fittingdata.start_count:]
    #keeps only the lines of spectral data
    fittingdata.replace_lines = []
    for i in np.arange(len(fittingdata.data_lines)):
        fittingdata.file_line = fittingdata.data_lines[i]
        #print('line: ', line)
        splitline = fittingdata.file_line.split()
        splitline[1] = str(fittingdata.channels[i].astype(int)) + '\n'
        replaceline = ' '.join(splitline)
        fittingdata.replace_lines.append(replaceline)
    text_list = fittingdata.header_lines + fittingdata.replace_lines
    filenamemod = fittingdata.file_name.replace('.txt', fittingdata.modification)
    text = "".join(text_list)
    #writing the file
    file = open(filenamemod, "w")
    file.write(text)
    file.close()
    fittingdata.file_content = ''  #zeroing all the holder spaces after use
    fittingdata.file_lines = ''
    fittingdata.header_lines = ''
    fittingdata.data_lines = ''
    fittingdata.replace_lines = []
    return


###########################
#  20190426 Donald Windover
#  This function reads in the *.txt file, passes the channels and energy
#  for modification
#

def bruker_msa_import(fittingdata):
    """function to open Bruker MSA format spectra files"""
    print(fittingdata.file_name)
    fittingdata.file_content = open(fittingdata.file_name)
    fittingdata.file_lines = fittingdata.file_content.readlines()
    fittingdata.file_content.close()
    fittingdata.line_count = 0
    for fittingdata.file_line in fittingdata.file_lines:
        # finds the start of the error data
        fittingdata.line_count = fittingdata.line_count +1
        #looks for the word 'Spectrum' in each line
        if fittingdata.file_line.find('XPERCHAN') != -1:
            splitline = fittingdata.file_line.split(':')
            fittingdata.calibration_lin = 1000 * float(splitline[1])
        if fittingdata.file_line.find('OFFSET') != -1:
            splitline = fittingdata.file_line.split(':')
            fittingdata.calibration_abs = -10 * float(splitline[1])
        if fittingdata.file_line.find('SPECTRUM') != -1:
            # startMSA local variable only for indexing end of MSA header
            start_msa = fittingdata.line_count
    fittingdata.data_lines = fittingdata.file_lines[start_msa:-1]
    #keeps only the lines of error data
    string = ''.join(fittingdata.data_lines)
    new_string = re.sub("\n", '', string)
    fittingdata.channels = np.fromstring(new_string, sep=',')
    fittingdata.energy_scale = (fittingdata.calibration_abs +
                                np.arange(4096) * fittingdata.calibration_lin)
    fittingdata.file_content = ''
    fittingdata.file_lines = ''
    fittingdata.file_line = ''
    fittingdata.data_lines = ''
    return


###########################
#  20190426 Donald Windover
#  This function reads in the *.SPX file, passes the channels and energy
#  for modification
#
def bruker_spx_import(fittingdata):
    """function to import channels and energy info from Bruker *.spx* file"""
    #
    #establish 4096 array to take the channel data from an spx file
    #for the Bruker spx data (assumes all 4096 channels present)
    #
    #counts_spx = np.zeros((1,4096))
    # prints which file is being converted
    #
    try:
        #opens the XML file
        tree = ET.parse(open(fittingdata.file_name, "r"))
        root = tree.getroot()
        print(r'SPXFile: ', fittingdata.file_name)
    except TypeError:
        #fails gracefully, if filename or format is not XML.
        print("Unable to open and parse input definition file: "
              + fittingdata.FileName)
    #pulls in the channle data
    for level_two in root:
        if level_two.find('Channels') is not None:
            channels = level_two.find('Channels')
            fittingdata.channels = np.asarray(channels.text.split(','), dtype=int)
            #print('import size: ', fittingdata.channels.shape)
        #pulls in the parameters needed for the txt file
        for level_three in level_two:
            if level_three.tag == 'TRTHeaderedClass':
                for level_four in level_three:
                    #pulls in the collection time information
                    if {'Type': 'TRTSpectrumHardwareHeader'} == level_four.attrib:
                        for level_five in level_four:
                            if level_five.tag == 'RealTime':
                                fittingdata.real_time_in_ms = np.float(
                                    level_five.text)
                            if level_five.tag == 'LifeTime':
                                fittingdata.life_time_in_ms = np.float(
                                    level_five.text)
                            if level_five.tag == 'PulseDensity':
                                fittingdata.pulse_density = level_five.text
                            if level_five.tag == 'ShapingTime':
                                fittingdata.shaping_time = np.float(
                                    level_five.text)
                    if {'Type' : 'TRTDetectorHeader'} == level_four.attrib:
                        for level_five in level_four:
                            #pulls is in the detector info
                            if level_five.tag == 'Type':
                                fittingdata.detector_type = level_five.text
                            if level_five.tag == 'DetectorThickness':
                                fittingdata.detector_thickness = float(level_five.text)
                            if level_five.tag == 'SiDeadLayerThickness':
                                fittingdata.si_dead_layer = level_five.text
                            if level_five.tag == 'WindowType':
                                fittingdata.window_type = level_five.text
            if {'Type': 'TRTSpectrumHeader'} == level_three.attrib:
                for level_four in level_three:
                    #pulls in the energy calibration info
                    if level_four.tag == 'Date':
                        date = level_four.text
                    if level_four.tag == 'Time':
                        time = level_four.text
                    if level_four.tag == 'ChannelCount':
                        fittingdata.no_channels = level_four.text
                    if level_four.tag == 'CalibAbs':
                        calibration_abs = np.float(level_four.text)
                    if level_four.tag == 'CalibLin':
                        calibration_lin = np.float(level_four.text)
                    if level_four.tag == 'SigmaAbs':
                        sigma_abs = np.float(level_four.text)
                    if level_four.tag == 'SigmaLin':
                        sigma_lin = np.float(level_four.text)
    #converts the time to the correct format
    time = datetime.strptime(time, "%H:%M:%S")
    fittingdata.time_measure = time.strftime("%I:%M:%S %p")
    #converts the date to the correct format
    date = datetime.strptime(date, "%d.%m.%Y")
    fittingdata.date_measure = date.strftime("%m/%d/%Y")
    # rescales energy calibration factors for the txt format
    fittingdata.calibration_abs = 1000 * calibration_abs
    fittingdata.calibration_lin = 1000 * calibration_lin
    #Energy used in the calucation of Mn FWHM (approximated on 2017/10/19)
    mn_energy = 5.900
    #Formula given by Bruker (Falk Reinhardt) on 2017/10/19
    sigma = np.sqrt(sigma_abs + mn_energy*sigma_lin)
    fwhm_factor = 1000 * np.sqrt(8*np.log(2))*sigma
    fittingdata.mn_fwhm = float(fwhm_factor)  #we now know the calc rather than needing a const.
    #print(fittingdata.mn_fwhm)
    #Energy scale calculation
    for i in np.arange(4096):
        fittingdata.energy_scale[i] = (fittingdata.calibration_abs +
                                       fittingdata.calibration_lin*i)/1000            
    return# provides the comma delimited list of channel intensity

###########################
#  20190426 Donald Windover
#  This function reads in the *.SPX file, passes the channels and energy
#  for modification, and generates a txt file in the Bruker output format
#
def bruker_spx_to_txt_convert(fittingdata):
    """function converting Bruker *.spx* to *.txt* """
    # prints which file is being converted
    print(fittingdata.file_name)
    #
    try:
        #opens the XML file
        tree = ET.parse(open(fittingdata.file_name, "r"))
        root = tree.getroot()
    except TypeError:
        #fails gracefully, if filename or format is not XML.
        print("Unable to open and parse input definition file: "
              + fittingdata.file_name)
    #pulls in the channle data
    for level_two in root:
        if level_two.find('Channels') is not None:
            channels = level_two.find('Channels')
            fittingdata.channels = np.fromstring((channels.text), sep=',')
        #pulls in the parameters needed for the txt file
        for level_three in level_two:
            if level_three.tag == 'TRTHeaderedClass':
                for level_four in level_three:
                    #pulls in the collection time information
                    if {'Type': 'TRTSpectrumHardwareHeader'} == level_four.attrib:
                        for level_five in level_four:
                            if level_five.tag == 'RealTime':
                                fittingdata.real_time_in_ms = np.float(
                                    level_five.text)
                            if level_five.tag == 'LifeTime':
                                fittingdata.life_time_in_ms = np.float(
                                    level_five.text)
                            if level_five.tag == 'PulseDensity':
                                fittingdata.pulse_density = level_five.text
                            if level_five.tag == 'ShapingTime':
                                fittingdata.shaping_time = np.float(
                                    level_five.text)
                    if {'Type' : 'TRTDetectorHeader'} == level_four.attrib:
                        for level_five in level_four:
                            #pulls is in the detector info
                            if level_five.tag == 'Type':
                                fittingdata.detector_type = level_five.text
                            if level_five.tag == 'DetectorThickness':
                                fittingdata.detector_thickness = float(level_five.text)
                            if level_five.tag == 'SiDeadLayerThickness':
                                fittingdata.si_dead_layer = level_five.text
                            if level_five.tag == 'WindowType':
                                fittingdata.window_type = level_five.text
            if {'Type': 'TRTSpectrumHeader'} == level_three.attrib:
                for level_four in level_three:
                    #pulls in the energy calibration info
                    if level_four.tag == 'Date':
                        date = level_four.text
                    if level_four.tag == 'Time':
                        time = level_four.text
                    if level_four.tag == 'ChannelCount':
                        fittingdata.no_channels = level_four.text
                    if level_four.tag == 'CalibAbs':
                        calibration_abs = np.float(level_four.text)
                    if level_four.tag == 'CalibLin':
                        calibration_lin = np.float(level_four.text)
                    if level_four.tag == 'SigmaAbs':
                        sigma_abs = np.float(level_four.text)
                    if level_four.tag == 'SigmaLin':
                        sigma_lin = np.float(level_four.text)
    #converts the time to the correct format
    time = datetime.strptime(time, "%H:%M:%S")
    fittingdata.time_measure = time.strftime("%I:%M:%S %p")
    #converts the date to the correct format
    date = datetime.strptime(date, "%d.%m.%Y")
    fittingdata.date_measure = date.strftime("%m/%d/%Y")
    # rescales energy calibration factors for the txt format
    fittingdata.calibration_abs = 1000 * calibration_abs
    fittingdata.calibration_lin = 1000 * calibration_lin
    #Energy used in the calucation of Mn FWHM (approximated on 2017/10/19)
    mn_energy = 5.900
    #Formula given by Bruker (Falk Reinhardt) on 2017/10/19
    sigma = np.sqrt(sigma_abs + mn_energy*sigma_lin)
    fwhm_factor = 1000 * np.sqrt(8*np.log(2))*sigma
    fittingdata.mn_fwhm = float(fwhm_factor)  #we now know the calc rather than needing a const.
    print(fittingdata.mn_fwhm)
    #Energy scale calculation
    for i in np.arange(4096):
        fittingdata.energy_scale[i] = (fittingdata.calibration_abs +
                                       fittingdata.calibration_lin*i)/1000
    #text file data formatting
    text_header = []
    text_header.append(r'Bruker Nano GmbH Berlin, Germany')
    text_header.append(r'esprit 1.9')
    text_header.append(r'')
    text_header.append(r'Date: ' + fittingdata.date_measure + ' '
                       + fittingdata.time_measure)
    text_header.append(r'Real time: ' + '%.0f' % fittingdata.real_time_in_ms)
    text_header.append(r'Life time: ' + '%.0f' % fittingdata.life_time_in_ms)
    text_header.append(r'Pulse density: ' + fittingdata.pulse_density)
    text_header.append(r'')
    text_header.append(r'')
    text_header.append(r'Detector type: ' + fittingdata.detector_type)
    text_header.append(r'Window type: ' + fittingdata.window_type)
    text_header.append(r'Detector thickness: ' + str(fittingdata.detector_thickness))
    text_header.append(r'Si dead layer:' + fittingdata.si_dead_layer)
    text_header.append(r'')
    text_header.append(r'Calibration, lin.: ' + str(fittingdata.calibration_lin))
    text_header.append(r'Calibration, abs.: ' + '%.3f' % fittingdata.calibration_abs)
    text_header.append(r'Mn FWHM: ' + '%.3f' % fittingdata.mn_fwhm)
    text_header.append(r'Fano factor: 0.116')
    text_header.append(r'Channels: ' + fittingdata.no_channels)
    text_header.append(r'')
    text_header.append(r'Energy Counts')
    #including energy and counts
    for i in np.arange(int(fittingdata.no_channels)):
        text_header.append('%.4f' % fittingdata.energy_scale[i] +
                           '    ' + '%.0f' % fittingdata.channels[i])
    text_header.append(r'')
    #combining the list of strings into one long string
    text = "\n".join(text_header)
    #chaning .spx to a .txt extension
    file_name_mod = fittingdata.file_name.replace('.spx', '_python.txt')
    #writing the file
    file = open(file_name_mod, "w")
    file.write(text)
    file.close()
    #returning to 2d arrays with the energy and channels info through fittingdata
    return



def test_io():
    """Funcion tests the spx, msa, and txt readers using sample files
    
    Parameters
    ----------
    
    txt_file : name of test Bruker XRF txt file
    msa_file : name of test Bruker XRF msa file
    spx_file : name of txt Bruker XRF spx file
    txt, msa, spx : instances of Class FittingData
    
    
    Example
    -------

    >>>> txt_file = r'test.txt'
    >>>> txt = FittingData(txt_file)
    >>>> bruker_txt_test(txt)
    >>>> bruker_txt_import(txt)
    >>>> bruker_txt_mod(txt)
    >>>> msa_file = r'test.msa'
    >>>> msa = FittingData(msa_file)
    >>>> bruker_msa_import(msa)
    >>>> spx_file = r'test2.spx'
    >>>> spx = FittingData(spx_file)
    >>>> bruker_spx_import(spx)
    >>>> bruker_spx_to_txt_convert(spx)
    """
    txt_file = r'test.txt'
    txt = FittingData(txt_file)
    bruker_txt_test(txt)
    bruker_txt_import(txt)
    bruker_txt_mod(txt)
    msa_file = r'test.msa'
    msa = FittingData(msa_file)
    bruker_msa_import(msa)
    spx_file = r'test2.spx'
    spx = FittingData(spx_file)
    bruker_spx_import(spx)
    bruker_spx_to_txt_convert(spx)
    return