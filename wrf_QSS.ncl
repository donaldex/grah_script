mple script to produce standard plots for a WRF quarter_ss run

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
;load "./WRFUserARW.ncl"

begin
;
; The WRF ARW input file.  
; This needs to have a ".nc" appended, so just do it.

  a = addfile("../wrfout_d01_0001-01-01_00:00:00.nc","r")

;  We generate plots, but what kind do we prefer?

;   type = "x11"
  type = "pdf"
;  type = "ps"
;  type = "ncgm"

  wks = gsn_open_wks(type,"plt_QSS")


; Set some basic resources
    res = True
    res@MainTitle     = "WRF Quarter SS"       
    res@InitTime      = False
    res@Footer        = False

    pltres = True

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;  What times and how many time steps are in the data set?

  times  = wrf_user_list_times(a)  ; get times in the file
  ntimes = dimsizes(times)         ; number of times in the file

; The specific height levels that we want the data interpolated to.

  height_levels = (/ 750., 1500., 4000., 9000. /)   ; heigth levels to plot
  nlevels         = dimsizes(height_levels)     ; number of height levels

; How big do we want the plot
plot_width = .6
plot_height = .6

; This is the big loop over all of the time periods to process.

  do it = 1,ntimes-1

    time = it
    res@TimeLabel                  = times(it)    
    res@vpWidthF                   = plot_width
    res@vpHeightF                  = plot_height

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; First get the variables we will need        

  p   = wrf_user_getvar(a, "pressure",time)    ; pressure
  th  = wrf_user_getvar(a,"th",time)    ; get temperature (C)
  u   = wrf_user_getvar(a,"ua",time)    ; ua is u averaged to mass points
  v   = wrf_user_getvar(a,"va",time)    ; va is v averaged to mass points
  w   = wrf_user_getvar(a,"wa",time)    ; vertical velocity
  z   = wrf_user_getvar(a, "z",time)    ; grid point height
  ter = wrf_user_getvar(a,"HGT",time)   ; need terrain height sometimes

  qv  = wrf_user_getvar(a, "QVAPOR",time) ; 
  if(isfilevar(a,"QCLOUD"))
    qc =   wrf_user_getvar(a, "QCLOUD",time)
  end if
  if(isfilevar(a,"QRAIN"))
    qr =   wrf_user_getvar(a, "QRAIN",time)
  end if
  if(isfilevar(a,"QSNOW"))
    qs =   wrf_user_getvar(a, "QSNOW",time)
  end if
  if(isfilevar(a,"QICE"))
    qi =   wrf_user_getvar(a, "QICE",time)
  end if
  if(isfilevar(a,"QGRAUP"))
    qg =   wrf_user_getvar(a, "QGRAUP",time)
  end if

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    do level = 0,nlevels-1

      height = height_levels(level) 


 ; Pressure
      p_plane  = wrf_user_intrp3d( p,z,"h",height,0.,False)
      opts_p   = res
      ;opts_p@FieldTitle            = p@description
      opts_p@PlotLevelID           = 0.001*height + " km"
      contour_p     = wrf_contour(a,wks,p_plane,opts_p)

 ; Theta
      th_plane = wrf_user_intrp3d(th,z,"h",height,0.,False)
      opts_th  = res
      ;opts_th@FieldTitle           = th@description
      opts_th@PlotLevelID          = 0.001*height + " km"
      opts_th@cnFillOn             = True
      opts_th@gsnSpreadColorEnd    = -10   
      contour_th     = wrf_contour(a,wks,th_plane,opts_th)

 ; Vertical Velocity
      w_plane  = wrf_user_intrp3d( w,z,"h",height,0.,False)
      w_plane = 100.*w_plane
      opts_w   = res
      ;opts_w@FieldTitle            = w@description
      opts_w@UnitLabel             = "m/3"
      opts_w@PlotLevelID           = 0.001*height + " km"
      opts_w@cnFillOn              = True
      opts_w@gsnSpreadColorEnd     = -3
      contour_w = wrf_contour(a,wks, w_plane,opts_w)

 ; Wind Vectors
      u_plane  = wrf_user_intrp3d( u,z,"h",height,0.,False)
      v_plane  = wrf_user_intrp3d( v,z,"h",height,0.,False)
      opts_vct = res
      opts_vct@FieldTitle          = "Winds"
      opts_vct@PlotLevelID         = 0.001*height + " km"
      opts_vct@NumVectors          = 30 
      opts_vct@vcGlyphStyle        = "LineArrow"
      opts_vct@vcRefAnnoOn         = True
      vector         =  wrf_vector(a,wks,u_plane, v_plane,opts_vct)

      plot = wrf_overlays(a,wks,(/contour_p, contour_th, vector/),pltres)
      plot = wrf_overlays(a,wks,(/contour_w, vector/),pltres)


 ; Basic Options for all cloud plots
      opts_clouds = res
      opts_clouds@cnFillOn           = True
      opts_clouds@UnitLabel          = "g/kg"
      opts_clouds@PlotLevelID        = 0.001*height + " km"
      opts_clouds@gsnSpreadColorEnd  = -10

      if (isvar("qv"))
        qv_plane  = wrf_user_intrp3d( qv,z,"h",height,0.,False)
        qv_plane  = qv_plane*1000.
        opts_qv = opts_clouds
        ;opts_qv@FieldTitle       = qv@description
        contour_qv     = wrf_contour(a,wks,qv_plane,opts_qv)
        plot = wrf_overlays(a,wks,(/contour_qv,vector/),pltres)
      end if

      if (isvar("qc"))
        qc_plane  = wrf_user_intrp3d( qc,z,"h",height,0.,False)
        qc_plane  = qc_plane*1000.
        opts_qc = opts_clouds
        ;opts_qc@FieldTitle       = qc@description
        contour_qc     = wrf_contour(a,wks,qc_plane,opts_qc)
        plot = wrf_overlays(a,wks,(/contour_qc,vector/),pltres)
      end if

      if (isvar("qr"))
        qr_plane  = wrf_user_intrp3d( qr,z,"h",height,0.,False)
        qr_plane  = qr_plane*1000.
        opts_qr = opts_clouds
        ;opts_qr@FieldTitle       = qr@description
        contour_qr     = wrf_contour(a,wks,qr_plane,opts_qr)
        plot = wrf_overlays(a,wks,(/contour_qr,vector/),pltres)
      end if

      if (isvar("qs"))
        qs_plane  = wrf_user_intrp3d( qs,z,"h",height,0.,False)
        qs_plane  = qs_plane*1000.
        opts_qs = opts_clouds
        ;opts_qs@FieldTitle       = qs@description
        contour_qs     = wrf_contour(a,wks,qs_plane,opts_qs)
        plot = wrf_overlays(a,wks,(/contour_qs,vector/),pltres)
      end if

      if (isvar("qi"))
        qi_plane  = wrf_user_intrp3d( qi,z,"h",height,0.,False)
        qi_plane  = qi_plane*1000.
        opts_qi = opts_clouds
        ;opts_qi@FieldTitle       = qi@description
        contour_qi     = wrf_contour(a,wks,qi_plane,opts_qi)
        plot = wrf_overlays(a,wks,(/contour_qi,vector/),pltres)
      end if

      if (isvar("qg"))
        qg_plane  = wrf_user_intrp3d( qg,z,"h",height,0.,False)
        qg_plane  = qg_plane*1000.
        opts_qg = opts_clouds
        ;opts_qg@FieldTitle       = qg@description
        contour_qg     = wrf_contour(a,wks,qg_plane,opts_qg)
        plot = wrf_overlays(a,wks,(/contour_qg,vector/),pltres)
      end if

    end do

  ;       ************************************************************

  end do  ;       end of the time loop

end
