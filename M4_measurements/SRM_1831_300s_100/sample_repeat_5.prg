Program filter_control;

//--------------------------------------------------------------
// Program measures a series of X,Y targets over a range of
// detector and filter configurations and optionally Z offsets
//
// Future implimentations will allow multiple X-ray sources
// center of a wafer.
//
// based off Bruker Caldera test script.  edited by DW last on 20180502
//
//--------------------------------------------------------------



var   ZFocus,X,Y,
      xySpeed,xyAcc,zSpeed,zAcc,
      XOut,YOut,ZOut,
      XFloat,YFloat,ZFloat,
      MeasureState,PulseRate,
      XEnd,YEnd,
      Value                                  : Double;
      //
      TargetList,ZOffsetList,
      ElementList,List                       : TStringList;
      LiveTime_FE,LiveTime_F1,
      LiveTime_F2,LiveTime_F3,
      LiveTime_F4,LiveTime_F5,
      TotalPoints,TotalTime,LiveTimeSum,
      NumberFilters,FilterMoves,
      RealTime,LifeTime,
      CameraIndex,BufSize,
      Timer,TimeLeft,Status,MoPoState,
      RealTime_FE                            : LongInt;
      //
      ActiveDetector,i,j,Tube                : Byte;
      //
      RhTube,MoTube,
      Det1,Det2,
      FE,F1,F2,F3,F4,F5,
      Moving,
      Running,Canceled,
      HighQuality,DoShow,AutomaticOnly,
      ShutterOpen,ZOffset                    : BOOLEAN;
      //
      HighVoltage_FE,Current_FE,
      HighVoltage_F1,Current_F1,
      HighVoltage_F2,Current_F2,
      HighVoltage_F3,Current_F3,
      HighVoltage_F4,Current_F4,
      HighVoltage_F5,Current_F5,
      DetSum,TubeSum                         : Cardinal;
      //
      DirectoryName,FileName,
      TargetDirectoryName,
      TargetFileName,ZOffsetFileName,
      ElementFileName,
      LineString,XString,YString,
      ListString,AFileName,
      Command,CoordString                    : String;
      //
      aBmp                                   : TBitmap;
      //
      ImgWidth                               : word;
      //
      TargetListCount,ZOffsetListCount,
      ElementListCount,
      TargetListIndex,ZOffsetListIndex,
      aWidth,aHeight,APixelFormat,
      PosInString                            : integer;


BEGIN
   ////////
   // Which tubes are used
   // NOTE - this version only uses Rh presently
   //
   RhTube := True; // Rh tube used
   MoTube := False; // Mo tube used
   //
   ////////
   // Which detectors are used
   //
   Det1 := True; // Towards computer
   Det2 := True; // Towards galley
   //
   ///////
   // Which filters are used
   //
   FE := True;      // Filter Empty
   F1 := False;      // Filter Al 0.012 mm
   F2 := False;      // Filter Al 0.1 mm
   F3 := False;      // Filter Al 0.6 mm
   F4 := False;      // Filter Al/Ti 0.1/0.025 mm
   F5 := False;      // Filter AlTiCu 0.1/.05/.025 mm
   //
   //////////
   // HV/current/time changes for each filter configuration
   //
   // Filter Empty
   //
   HighVoltage_FE := 50000;  // in Volts
   Current_FE     := 300;    // in mA
   LiveTime_FE    := 300000;   // in ms
   RealTime_FE    := 300000;   // in ms
   //
   // Filter Al 0.012 mm
   //
   HighVoltage_F1 := 50000;  // in Volts
   Current_F1     := 600;    // in mA
   LiveTime_F1    := 100;   // in ms
   //
   // Filter Al 0.1 mm
   //
   HighVoltage_F2 := 50000;  // in Volts
   Current_F2     := 600;    // in mA
   LiveTime_F2    := 100;   // in ms
   //
   // Filter Al 0.6 mm
   //
   HighVoltage_F3 := 50000;  // in Volts
   Current_F3     := 600;    // in mA
   LiveTime_F3    := 100;   // in ms
   //
   // Filter Al/Ti 0.1/0.025 mm
   //
   HighVoltage_F4 := 50000;  // in Volts
   Current_F4     := 600;    // in mA
   LiveTime_F4    := 100;   // in ms
   //
   // Filter AlTiCu 0.1/.05/.025 mm
   //
   HighVoltage_F5 := 50000;  // in Volts
   Current_F5     := 600;    // in mA
   LiveTime_F5    := 100;   // in ms
   //
   /////////
   // Sudirectory where and prefix name of files to be saved
   //
   DirectoryName := 'C:\M4 User\Xrf\Data\windover\SRM_1831_300s_5\';
   FileName:= DirectoryName + 'SRM_1831_300s_5_';
   //
   ////////
   //  Subdirectory where XY Targets and Z offsets are located.
   //      NOTE - always use the 'Z_offset_none.txt' file
   //        if you want no Z_offsets!!
   //
   TargetDirectoryName := 'C:\M4 User\Xrf\Data\windover\SRM_1831_300s_5\';
   TargetFileName := TargetDirectoryName + 'target_locations_sample.txt';
   ZOffsetFileName := TargetDirectoryName + 'Z_offset_5.txt'
   ElementFileName := TargetDirectoryName + 'sample_name.txt'
   //
   //////////
   //  Z in focus
   //  VERY IMPORTANT - focus carefully prior to run and update value
   //
   ZFocus := 108.56
   //
   //X := 101.44; //Target positions only used for testing purposes
   //Y := 70.32;  //Target positions only used for testing purposes
   //
   //
   ////////////////////////
   ////////////////////////
   //
   // ALL settings below are fixed !!
   //
   // defaults to slow down drives during scanning
   xySpeed  := 10;
   xyAcc    := 10;
   zSpeed   := 10;
   zAcc     := 10;
   //
   //
    LineString :=''
   // defaults to indicate if position reads did not work correctly
   XOut := 999;
   YOut := 999;
   ZOut := 999;
   Moving := False;
   MoPoState := 999;
   Value := 30; //parameter used in estimating the end of files.
   //
   // loading of target coordinates for scanning
   //
   TargetList := TStringList.create;
   TargetList.LoadFromFile(TargetFileName);
   TargetListCount := TargetList.Count;
   //
   // loading z offsets
   //
   ZOffsetList := TStringList.create;
   ZOffsetList.LoadFromFile(ZOffsetFileName);
   ZOffsetListCount := ZOffsetList.Count;
   //
   // loading Element names
   //
   ElementList := TStringList.create;
   ElementList.LoadFromFile(ElementFileName);
   ElementListCount := ZOffsetList.Count;
   //
   ///////////////////
   // Time estimates
   //
   //////
   // Count number of targets
   //
   TotalPoints := TargetListCount*ZOffsetListCount;
   //
   DetSum :=0;
   TubeSum :=0
   NumberFilters := 0;
   FilterMoves := 0;    //variable for testing if filter is in the right position
   LiveTimeSum :=0;
   //
   //////
   // Check if both detectors will collect data
   //
   //
   If Det1 = True Then
      Begin
      DetSum := DetSum +1;
      End;
   If Det2 = True Then
      Begin
      DetSum := DetSum +1;
      End;   //
   //////
   // Check if both tubes are running
   //
   If RhTube = True Then
      Begin
      TubeSum := TubeSum + 1;
      End;
   If MoTube = True Then
      Begin
      TubeSum := TubeSum + 1;
      End;
   //
   //////
   // checking how many filters are used
   //

   If FE = True Then
      Begin
      NumberFilters := NumberFilters + 1;
      LiveTimeSum := LiveTimeSum + LiveTime_Fe;
      End;
   If F1 = True Then
      Begin
      NumberFilters := NumberFilters + 1;
      LiveTimeSum := LiveTimeSum + LiveTime_F1;
      End;
   If F2 = True Then
      Begin
      NumberFilters := NumberFilters + 1;
      LiveTimeSum := LiveTimeSum + LiveTime_F2;
      End;
   If F3 = True Then
      Begin
      NumberFilters := NumberFilters + 1;
      LiveTimeSum := LiveTimeSum + LiveTime_F3;
      End;
   If F4 = True Then
      Begin
      NumberFilters := NumberFilters + 1;
      LiveTimeSum := LiveTimeSum + LiveTime_F4;
      End;
   If F5 = True Then
      Begin
      NumberFilters := NumberFilters + 1;
      LiveTimeSum := LiveTimeSum + LiveTime_F5;
      End;
   TotalTime := (TotalPoints * DetSum * TubeSum * LiveTimeSum) / 1000 / 60;
   //
   writeln('total points : ' + IntToStr(TotalPoints))
   writeln('number of detectors :' + IntToStr(DetSum))
   writeln('number of tubes :' +IntToStr(TubeSum))
   writeln('number of filters :' + IntToStr(NumberFilters))
   writeln('total time per point :' +IntToStr(LiveTimesum))
   writeln('total time : ' + IntToStr(TotalTime) + ' (in minutes)')
   writeln('first element: ' + ElementList[0])
   //
   /////////////////////////////////////////
   /////////////////////////////////////////
   //
   // USE this END to during your time and position estimation
   // Comment it out when you are ready to run!!
   //
   //END.
   //
   ///////////
   //
   //////////
   // create list for X,Y,Z,file name for each wafer
   //
   LIST := TStringList.Create;
   //
   // Start of For Loop NEST
   //
   //////////////////////////////////////////////
   //
   //////////////////////////////////////////////
   // For loop of X,Y coordinates from file "TargetList"
   //
   FOR TargetListIndex:=0 to TargetListCount-1 DO
      Begin
      writeln('Number of X,Y locations: ' + IntToStr(TargetListCount));
      //
      /////////
      // Pull in the X,Y coordinates from first line in the target file
      //
      LineString := TargetList[TargetListIndex];
      //writeln(LineString);
      PosInString := pos(',', LineString);
      XString := copy(LineString, 1, PosInString-1);
      XFloat := StrToFloat(XString);
      delete(Linestring, 1, PosInString);
      YString := LineString;
      YFloat := StrToFloat(YString);
      MoveStageToXY(XFloat+0.1,YFloat+0.1,xySpeed,xyAcc,TRUE);
      MoveStageToXY(XFloat,YFloat,xySpeed,xyAcc,TRUE);
      sleep(500);
      //
      //////////
      // For loop of Z offsets from file "ZOffsetList"
      //
      FOR ZOffsetListIndex:=0 to ZOffsetListCount-1 DO
         Begin
         ///////
         // Determine Z shift from list line by line
         //
         LineString := ZOffsetList[ZOffsetListIndex];
         writeln(LineString)
         ZFloat := StrToFloat(LineString)
         MoveStageToZ(ZFocus+ZFloat,zSpeed,zAcc,True)
         sleep(200);
         ///////////////
         // Check X,Y,Z positions and stor this info for list inclusion
         //
         GetStagePositionAndState(XOut,YOut,ZOut,Moving,MoPoState);
         //
         ///////////////////////////////////////////////////
         //  Rh Tube scans section
         // End;
         If RhTube = True Then
            Begin
            ///////////
            //Opens Rh X-ray shutter!
            //
            XRayTubeSetConfiguration(1,HighVoltage_FE,Current_FE,0);
            //
            // NOTE: Need to find out how to open Mo tube shutter
            Command:='XR+';
            SendRCLCommand(0,true,Command);

            //
            /////////////
            //  FE Filter settings
            //
            If FE = True Then
               Begin
               //
               ////////
               // Change Tube power to FE settings
               //
               XRayTubeSetConfiguration(1,HighVoltage_FE,Current_FE,0);
               //
               ////////
               // Change Filter to FE
               //
               writeln('FilterMoves: ' + IntToStr(FilterMoves));
               ///////////
               // checks if filters have not moved yet & performs one move
               //
               If FilterMoves < 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW1 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               writeln('NumberFilters: ' + IntToStr(NumberFilters));
               ///////////
               // moves filter each time if filter count > 1
               //
               If NumberFilters > 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW1 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               If Det1 = True Then
                  Begin
                  ////////
                  // Turn on detector towards computer
                  //
                  ActiveDetector:=1;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  //SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_FE);
                  SPUStartMeasurement(ActiveDetector,RealTime_FE);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det1: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, FE, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_FE_D1' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 1 scan done');
                  End;
               If Det2 = True Then
                  Begin
                  ////////
                  // Turn on detector towards galley
                  //
                  ActiveDetector:=2;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  //SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_FE);
                  SPUStartMeasurement(ActiveDetector,RealTime_FE);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det2: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, FE, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_FE_D2' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 2 scan done');
                  End;
               End;
            // close of FE case
            //
            //
            /////////////
            //  F1 Filter settings
            //
            If F1 = True Then
               Begin
               //
               ////////
               // Change Tube power to F1 settings
               //
               XRayTubeSetConfiguration(1,HighVoltage_F1,Current_F1,0);
               //
               ////////
               // Change Filter to F1
               //
               writeln('FilterMoves: ' + IntToStr(FilterMoves));
               ///////////
               // checks if filters have not moved yet & performs one move
               //
               If FilterMoves < 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW2 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               writeln('NumberFilters: ' + IntToStr(NumberFilters));
               ///////////
               // moves filter each time if filter count > 1
               //
               If NumberFilters > 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW2 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               If Det1 = True Then
                  Begin
                  ////////
                  // Turn on detector towards computer
                  //
                  ActiveDetector:=1;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_F1);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det1: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, F1, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_F1_D1' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 1 scan done');
                  End;
               If Det2 = True Then
                  Begin
                  ////////
                  // Turn on detector towards galley
                  //
                  ActiveDetector:=2;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_F1);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det2: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, F1, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_F1_D2' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 2 scan done');
                  End;
               //
               //
               End;
            // end of F1 case
            //////////////////
            //
            //
            /////////////
            //  F2 Filter settings
            //
            If F2 = True Then
               Begin
               //
               ////////
               // Change Tube power to F2 settings
               //
               XRayTubeSetConfiguration(1,HighVoltage_F2,Current_F2,0);
               //
               ////////
               // Change Filter to F2
               //
               writeln('FilterMoves: ' + IntToStr(FilterMoves));
               ///////////
               // checks if filters have not moved yet & performs one move
               //
               If FilterMoves < 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW3 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               writeln('NumberFilters: ' + IntToStr(NumberFilters));
               ///////////
               // moves filter each time if filter count > 1
               //
               If NumberFilters > 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW3 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               If Det1 = True Then
                  Begin
                  ////////
                  // Turn on detector towards computer
                  //
                  ActiveDetector:=1;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_F2);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det1: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, F2, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_F2_D1' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 1 scan done');
                  End;
               If Det2 = True Then
                  Begin
                  ////////
                  // Turn on detector towards galley
                  //
                  ActiveDetector:=2;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_F2);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det2: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, F2, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_F2_D2' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 2 scan done');
                  End;
               //
               //
               End;
            // end of F2 case
            //////////////////
            //
            //
            //
            /////////////
            //  F3 Filter settings
            //
            If F3 = True Then
               Begin
               //
               ////////
               // Change Tube power to F3 settings
               //
               XRayTubeSetConfiguration(1,HighVoltage_F3,Current_F3,0);
               //
               ////////
               // Change Filter to F3
               //
               writeln('FilterMoves: ' + IntToStr(FilterMoves));
               ///////////
               // checks if filters have not moved yet & performs one move
               //
               If FilterMoves < 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW4 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               writeln('NumberFilters: ' + IntToStr(NumberFilters));
               ///////////
               // moves filter each time if filter count > 1
               //
               If NumberFilters > 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW4 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               If Det1 = True Then
                  Begin
                  ////////
                  // Turn on detector towards computer
                  //
                  ActiveDetector:=1;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_F3);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det1: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, F3, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_F3_D1' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 1 scan done');
                  End;
               If Det2 = True Then
                  Begin
                  ////////
                  // Turn on detector towards galley
                  //
                  ActiveDetector:=2;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_F3);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det2: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, F3, D1 case
                  //
                   AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_F3_D2' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 2 scan done');
                  End;
               //
               //
               End;
            // end of F3 case
            //////////////////
            //
            //
            /////////////
            //  F4 Filter settings
            //
            If F4 = True Then
               Begin
               //
               ////////
               // Change Tube power to F4 settings
               //
               XRayTubeSetConfiguration(1,HighVoltage_F4,Current_F4,0);
               //
               ////////
               // Change Filter to F4
               //
               writeln('FilterMoves: ' + IntToStr(FilterMoves));
               ///////////
               // checks if filters have not moved yet & performs one move
               //
               If FilterMoves < 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW5 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               writeln('NumberFilters: ' + IntToStr(NumberFilters));
               ///////////
               // moves filter each time if filter count > 1
               //
               If NumberFilters > 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW5 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               If Det1 = True Then
                  Begin
                  ////////
                  // Turn on detector towards computer
                  //
                  ActiveDetector:=1;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_F4);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det1: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, F4, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_F4_D1' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 1 scan done');
                  End;
               If Det2 = True Then
                  Begin
                  ////////
                  // Turn on detector towards galley
                  //
                  ActiveDetector:=2;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_F4);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det2: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, F4, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_F4_D2' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 2 scan done');
                  End;
               //
               //
               End;
            // end of F4 case
            //////////////////
            //
            //
            /////////////
            //  F5 Filter settings
            //
            If F5 = True Then
               Begin
               //
               ////////
               // Change Tube power to F5 settings
               //
               XRayTubeSetConfiguration(1,HighVoltage_F5,Current_F5,0);
               //
               ////////
               // Change Filter to F5
               //
               writeln('FilterMoves: ' + IntToStr(FilterMoves));
               ///////////
               // checks if filters have not moved yet & performs one move
               //
               If FilterMoves < 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW6 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               writeln('NumberFilters: ' + IntToStr(NumberFilters));
               ///////////
               // moves filter each time if filter count > 1
               //
               If NumberFilters > 1 Then
                  Begin
                  FilterMoves := FilterMoves + 1 ;
                  Command:='RKFW6 1';
                  Status := SendRCLCommand(0,true,Command);
                  sleep(15000);
                  writeln('Filter command sent')
                  End;
               If Det1 = True Then
                  Begin
                  ////////
                  // Turn on detector towards computer
                  //
                  ActiveDetector:=1;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_F5);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det1: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, F5, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_F5_D1' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 1 scan done');
                  End;
               If Det2 = True Then
                  Begin
                  ////////
                  // Turn on detector towards galley
                  //
                  ActiveDetector:=2;
                  SPUCombineSpectrometer(ActiveDetector)
                  //
                  ////////
                  // Collect data from detector towards computer
                  //
                  SPUStartLifeTimeMeasurement(ActiveDetector,LiveTime_F5);
                  Timer :=1;
                  REPEAT
                     SPUGetMeasureState(ActiveDetector,Running,MeasureState,PulseRate,RealTime,Lifetime);
                     sleep(50);
                     Timer := Timer +1;
                  UNTIL MeasureState > Value;
                  writeln('50ms counter det2: ' + IntToStr(Timer));
                  TimeLeft :=  100 * Timer;
                  sleep(TimeLeft);
                  sleep(200);
                  SPUReadSpectrum(ActiveDetector);
                  //
                  /////////
                  // Customize the filename for Rh, F5, D1 case
                  //
                  AFileName := FileName + ElementList[TargetListIndex] +
                  '_Rh_F5_D2' +
                  '_' + IntToStr(TargetListIndex) +
                  '_' + IntToStr(ZOffsetListIndex)
                  SaveSpectrum(ActiveDetector,AFileName + '.spx');
                  ListString := FloatToStr(XOut) + ',' +
                  FloatToStr(YOut)+ ',' +
                  FloatToStr(ZOut);
                  List.Add(ListString  + AFileName);
                  writeln('det 2 scan done');
                  End;
               //
               //
               End;
            // end of F5 case
            //////////////////
            //
            //
            ////////////////
            // end of Filter loops
            //
            //////////////////
            //
            /////////////
            //
            End;
         // End of Rh Tube scan case
         ///////////////////////////////////
         //
         //
         //////////
         // Z for loop
         End;
         //
      //////////
      // X,Y target loop
      End;
   List.SaveToFile(FileName + '_XYZ.txt');
   List.Free;
   TargetList.Free
   ZOffsetList.Free
End.

   //
   //
   //////////////////////////////////////////
   ///////////////////////////////////////////