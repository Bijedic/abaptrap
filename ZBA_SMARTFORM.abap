*&---------------------------------------------------------------------*
*& Report  ZBA_SMARTFORM
*&
*&---------------------------------------------------------------------*
*& Author: Arvio Bjedi
*&
*&---------------------------------------------------------------------*
report  zba_smartform.

*&---------------------------------------------------------------------*
*& Selection screen
*&---------------------------------------------------------------------*
selection-screen begin of block b1 with frame title text-001.
parameters: p_vbeln type vbrk-vbeln obligatory.
parameters: p_smart radiobutton group r1,
            p_sapsc radiobutton group r1,
            p_adobe radiobutton group r1.
selection-screen end of block b1.

*&---------------------------------------------------------------------*
*& Start-of-selection
*&---------------------------------------------------------------------*
start-of-selection.

  data: gt_vbrk type zba_vbrk_t,
        gt_adrc type zba_adrc_t,
        gt_kna1 type zba_kna1_t,
        gt_invoice type zba_invoice_t,
        gs_value type zba_s_value,
        gs_vbrk type zba_s_vbrk,
        gs_kna1 type zba_s_kna1,
        gs_invoice type zba_s_invoice,
        gs_adrc type zba_s_adrc,
        gs_row type string,                                 "#EC NEEDED
        gt_row type table of string,
        gt_rows type table of string.

  perform selection_vbrk changing gt_vbrk .
  perform selection_kna1 changing gt_kna1 .
  perform selection_adrc using gt_vbrk changing gt_adrc .

  if p_smart is not initial.
    perform display_select tables gt_vbrk gt_kna1 gt_adrc
                           changing gt_invoice gs_value.
    perform display_data_smartform using gt_vbrk gt_kna1 gt_adrc
                                         gt_invoice gs_value.
  endif.

  if p_sapsc is not initial.
    perform open_start_form.
    perform display_data_sapscript .
    perform close_end_form.
  endif.

  if p_adobe is not initial.
    perform display_select tables gt_vbrk gt_kna1 gt_adrc
                          changing gt_invoice gs_value.
    perform display_data_adobeform using gt_vbrk gt_kna1 gt_adrc
                                         gt_invoice gs_value.
  endif.
*&---------------------------------------------------------------------*
*&      Form  SELECTION
*&---------------------------------------------------------------------*
form selection_vbrk changing ct_vbrk type zba_vbrk_t.

  select vbrk~vbeln vbrk~fkdat vbrp~posnr vbrp~arktx vbrp~matnr
         vbrp~vrkme vbrp~fkimg vbrp~netwr vbrp~mwsbp tvzbt~vtext
         vbrk~zterm tinct~bezei vbrk~inco1 vbrk~inco2 vbrk~bukrs
    from vbrk join vbrp on vbrp~vbeln = vbrk~vbeln
              join tinct on tinct~inco1 = vbrk~inco1
              join tvzbt on tvzbt~zterm = vbrk~zterm
    into corresponding fields of table ct_vbrk
    where vbrk~vbeln = p_vbeln
      and tinct~spras = 'E'
      and tvzbt~spras = 'E'.

endform.                    " SELECTION
*&---------------------------------------------------------------------*
*&      Form  SELECTION_KNA1
*&---------------------------------------------------------------------*
form selection_kna1 changing ct_kna1 type zba_kna1_t.

  select kna1~name1 kna1~stceg kna1~stras kna1~ort01 t005t~landx
         kna1~telf1
    from kna1 join vbrk on kna1~kunnr = vbrk~kunrg
              join t001 on vbrk~bukrs = t001~bukrs
              join t005t on t001~land1 = t005t~land1
    into corresponding fields of table ct_kna1
    where vbrk~vbeln = p_vbeln
    and t005t~spras = 'E'.

endform.                    " SELECTION_KNA1
*&---------------------------------------------------------------------*
*&      Form  SELECTION_ADRC
*&---------------------------------------------------------------------*
form selection_adrc  using    ut_vbrk type zba_vbrk_t
                     changing ct_adrc type zba_adrc_t.
  if ut_vbrk is not initial.
    select adrc~name1 adrc~street adrc~house_num1 adrc~city1
           t001~stceg t001~bukrs t005t~landx
      from t001 join adrc on adrc~addrnumber = t001~adrnr
                join kna1 on kna1~stceg = t001~stceg
                join t005t on t001~land1 = t005t~land1
      into corresponding fields of table ct_adrc
      for all entries in ut_vbrk
      where t001~bukrs = ut_vbrk-bukrs
      and t005t~spras = 'E'.
  endif.
endform.                    " SELECTION_ADRC
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_SELECT
*&---------------------------------------------------------------------*
form display_select tables tt_vbrk type zba_vbrk_t
                           tt_kna1 type zba_kna1_t
                           tt_adrc type zba_adrc_t
                  changing ct_invoice type zba_invoice_t
                           cs_value type zba_s_value.

  data: ls_vbrk type zba_s_vbrk,
        ls_invoice type zba_s_invoice,
        ls_kna1 type zba_s_kna1,
        ls_adrc type zba_s_adrc,
        lt_line type standard table of tline,
        ls_line type tline,
        lv_name type thead-tdname,
        lv_text type tline-tdline.

  loop at tt_vbrk into ls_vbrk.
    concatenate ls_vbrk-vbeln ls_vbrk-posnr into lv_name.

    call function 'READ_TEXT'
      exporting
        client                  = sy-mandt
        id                      = '0002'
        language                = 'E'
        name                    = lv_name
        object                  = 'VBBP'
      tables
        lines                   = lt_line
      exceptions
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        others                  = 8.
    if sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
    loop at lt_line into ls_line.
      lv_text = ls_line-tdline.
    endloop.
    ls_vbrk-text = lv_text.
    modify tt_vbrk from ls_vbrk.
  endloop.
  loop at tt_vbrk into ls_vbrk.
    clear ls_invoice.
    ls_invoice-vbeln = ls_vbrk-vbeln.
    ls_invoice-fkdat = ls_vbrk-fkdat.
    ls_invoice-posnr = ls_vbrk-posnr.
    ls_invoice-arktx = ls_vbrk-arktx.
    ls_invoice-matnr = ls_vbrk-matnr.
    ls_invoice-vrkme = ls_vbrk-vrkme.
    ls_invoice-fkimg = ls_vbrk-fkimg.
    ls_invoice-netwr = ls_vbrk-netwr.
    ls_invoice-mwsbp = ls_vbrk-mwsbp.
    ls_invoice-vtext = ls_vbrk-vtext.
    ls_invoice-zterm = ls_vbrk-zterm.
    ls_invoice-bezei = ls_vbrk-bezei.
    ls_invoice-inco1 = ls_vbrk-inco1.
    ls_invoice-inco2 = ls_vbrk-inco2.
    ls_invoice-kunrg = ls_vbrk-kunrg.
    ls_invoice-text  = ls_vbrk-text.
    ls_invoice-pric = ( ls_vbrk-netwr / ls_vbrk-fkimg ).

    clear ls_kna1.
    read table tt_kna1 into ls_kna1 with key kunnr  = ls_vbrk-kunrg.
    if sy-subrc = 0.
      ls_invoice-name1 = ls_kna1-name1.
      ls_invoice-stceg = ls_kna1-stceg.
      ls_invoice-stras = ls_kna1-stras.
      ls_invoice-ort01 = ls_kna1-ort01.
      ls_invoice-landx = ls_kna1-landx.
      ls_invoice-telef1 = ls_kna1-telef1.

      clear ls_adrc.
      read table tt_adrc into ls_adrc with key bukrs = ls_vbrk-bukrs.
      if sy-subrc = 0.
        ls_invoice-name1_1 = ls_adrc-name1.
        ls_invoice-street = ls_adrc-street.
        ls_invoice-house_num1 = ls_adrc-house_num1.
        ls_invoice-city1 = ls_adrc-city1.
        ls_invoice-landx_1 = ls_adrc-landx.
        ls_invoice-stceg_1 = ls_adrc-stceg.

      endif.
    endif.
    cs_value-gv_tot1 = cs_value-gv_tot1 + ls_vbrk-netwr.
    cs_value-gv_tot2 = cs_value-gv_tot2 + ls_vbrk-mwsbp.

    shift ls_invoice-posnr left deleting leading '0'.
    append ls_invoice to ct_invoice.

  endloop.
endform.                    " DISPLAY_SELECT
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA_SF
*&---------------------------------------------------------------------*
form display_data_smartform using ut_vbrk type zba_vbrk_t
                                  ut_kna1 type zba_kna1_t
                                  ut_adrc type zba_adrc_t
                                  ut_invoice type zba_invoice_t
                                  us_value type zba_s_value.
  data: lv_fname type rs38l_fnam.

  call function 'SSF_FUNCTION_MODULE_NAME'
    exporting
      formname           = 'ZBA_SMARTFORM'
    importing
      fm_name            = lv_fname
    exceptions
      no_form            = 1
      no_function_module = 2
      others             = 3.
  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
            with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

  call function lv_fname
    exporting
      gt_vbrk          = ut_vbrk
      gt_invoice       = ut_invoice
      gs_value         = us_value
      gt_adrc          = ut_adrc
      gt_kna1          = ut_kna1
    exceptions
      formatting_error = 1
      internal_error   = 2
      send_error       = 3
      user_canceled    = 4
      others           = 5.
  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
            with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

endform.                    " DISPLAY_DATA
*&---------------------------------------------------------------------*
*&      Form  OPEN_START_FORM
*&---------------------------------------------------------------------*
form open_start_form .

  call function 'OPEN_FORM'
    exporting
      form                        = 'ZBA_FORM_SCRIPT'
    exceptions
      canceled                    = 1
      device                      = 2
      form                        = 3
      options                     = 4
      unclosed                    = 5
      mail_options                = 6
      archive_error               = 7
      invalid_fax_number          = 8
      more_params_needed_in_batch = 9
      spool_error                 = 10
      codepage                    = 11
      others                      = 12.
  if sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

  call function 'START_FORM'
    exporting
      form        = 'ZBA_FORM_SCRIPT'
      language    = 'E'
      startpage   = 'PAGE1'
      program     = 'ZBA_SMARTFORM'
    exceptions
      form        = 1
      format      = 2
      unended     = 3
      unopened    = 4
      unused      = 5
      spool_error = 6
      codepage    = 7
      others      = 8.
  if sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
  call function 'WRITE_FORM'
exporting
*   ELEMENT                        = ' '
  window                         = 'GRAPH1'
exceptions
  element                        = 1
  function                       = 2
  type                           = 3
  unopened                       = 4
  unstarted                      = 5
  window                         = 6
  bad_pageformat_for_print       = 7
  spool_error                    = 8
  codepage                       = 9
  others                         = 10
         .
  if sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

  call function 'WRITE_FORM'
    exporting
      element                  = 'BOXBOX'
      window                   = 'WINDOW1'
    exceptions
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      others                   = 10.
  if sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  endif.

  call function 'WRITE_FORM'
    exporting
      element                  = 'HEAD'
      window                   = 'MAIN'
    exceptions
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      others                   = 10.
  if sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  endif.

  call function 'WRITE_FORM'
    exporting
      element                  = 'TABLE'
      window                   = 'MAIN'
    exceptions
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      others                   = 10.
  if sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  endif.
  call function 'WRITE_FORM'
    exporting
      element                  = 'ADDR'
      window                   = 'ADDR'
    exceptions
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      others                   = 10.
  if sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
  call function 'WRITE_FORM'
    exporting
      element                  = 'CUS'
      window                   = 'CUSTOMER'
    exceptions
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      others                   = 10.
  if sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
  call function 'WRITE_FORM'
    exporting
      element                  = 'INV'
      window                   = 'INBOLD'
    exceptions
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      others                   = 10.
  if sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

  call function 'WRITE_FORM'
    exporting
      element                  = 'INVO'
      window                   = 'IN_NR_DT'
    exceptions
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      others                   = 10.
  if sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

  call function 'WRITE_FORM'
    exporting
      element                  = 'PAG'
      window                   = 'PAGENR'
    exceptions
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      others                   = 10.
  if sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

  call function 'WRITE_FORM'
    exporting
      element                  = 'FOOTER'
      window                   = 'TOTAL'
    exceptions
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      others                   = 10.
  if sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.
endform.                    " OPEN_START_FORM
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA_SAPSCRIPT
*&---------------------------------------------------------------------*
form display_data_sapscript .

  data: lt_line type standard table of tline,
        ls_line type tline,
        lv_name type thead-tdname,
        lv_text type tline-tdline.

  loop at gt_vbrk into gs_vbrk .
    concatenate gs_vbrk-vbeln gs_vbrk-posnr into lv_name.

    call function 'READ_TEXT'
      exporting
        client                  = '800'
        id                      = '0002'
        language                = 'E'
        name                    = lv_name
        object                  = 'VBBP'
      tables
        lines                   = lt_line
      exceptions
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        others                  = 8.
    if sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.

    clear ls_line.
    loop at lt_line into ls_line.
      lv_text = ls_line-tdline.


    refresh gt_rows.
    call function 'RKD_WORD_WRAP'
      exporting
        textline            = lv_text
        outputlen           = 35
      tables
        out_lines           = gt_rows
      exceptions
        outputlen_too_large = 1
        others              = 2.
    if sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.
    append lines of gt_rows to gt_row.
     endloop.

    clear gs_invoice.
    gs_invoice-vbeln = gs_vbrk-vbeln.
    gs_invoice-fkdat = gs_vbrk-fkdat.
    gs_invoice-posnr = gs_vbrk-posnr.
    gs_invoice-arktx = gs_vbrk-arktx.
    gs_invoice-matnr = gs_vbrk-matnr.
    gs_invoice-vrkme = gs_vbrk-vrkme.
    gs_invoice-fkimg = gs_vbrk-fkimg.
    gs_invoice-netwr = gs_vbrk-netwr.
    gs_invoice-mwsbp = gs_vbrk-mwsbp.
    gs_invoice-vtext = gs_vbrk-vtext.
    gs_invoice-zterm = gs_vbrk-zterm.
    gs_invoice-bezei = gs_vbrk-bezei.
    gs_invoice-inco1 = gs_vbrk-inco1.
    gs_invoice-inco2 = gs_vbrk-inco2.
    gs_invoice-kunrg = gs_vbrk-kunrg.
    gs_invoice-text  = gs_vbrk-text.
    gs_invoice-pric = ( gs_vbrk-netwr / gs_vbrk-fkimg ).

    clear gs_kna1.
    read table gt_kna1 into gs_kna1 with key kunnr  = gs_vbrk-kunrg.
    if sy-subrc = 0.
      gs_invoice-name1 = gs_kna1-name1.
      gs_invoice-stceg = gs_kna1-stceg.
      gs_invoice-stras = gs_kna1-stras.
      gs_invoice-ort01 = gs_kna1-ort01.
      gs_invoice-landx = gs_kna1-landx.
      gs_invoice-telef1 = gs_kna1-telef1.

      clear gs_adrc.
      read table gt_adrc into gs_adrc with key bukrs = gs_vbrk-bukrs.
      if sy-subrc = 0.
        gs_invoice-name1_1 = gs_adrc-name1.
        gs_invoice-street = gs_adrc-street.
        gs_invoice-house_num1 = gs_adrc-house_num1.
        gs_invoice-city1 = gs_adrc-city1.
        gs_invoice-landx_1 = gs_adrc-landx.
        gs_invoice-stceg_1 = gs_adrc-stceg.

      endif.
    endif.
    gs_value-gv_tot1 = gs_value-gv_tot1 + gs_vbrk-netwr.
    gs_value-gv_tot2 = gs_value-gv_tot2 + gs_vbrk-mwsbp.
    append gs_invoice to gt_invoice.

    call function 'WRITE_FORM'
      exporting
        element                  = 'MATERIALS'
        type                     = 'BODY'
        window                   = 'MAIN'
      exceptions
        element                  = 1
        function                 = 2
        type                     = 3
        unopened                 = 4
        unstarted                = 5
        window                   = 6
        bad_pageformat_for_print = 7
        spool_error              = 8
        codepage                 = 9
        others                   = 10.
    if sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.

    loop at gt_row into gs_row.
      call function 'WRITE_FORM'
        exporting
          element                  = 'DESC'
          type                     = 'BODY'
          window                   = 'MAIN'
        exceptions
          element                  = 1
          function                 = 2
          type                     = 3
          unopened                 = 4
          unstarted                = 5
          window                   = 6
          bad_pageformat_for_print = 7
          spool_error              = 8
          codepage                 = 9
          others                   = 10.
      if sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      endif.
    endloop.
  endloop.

endform.                    " DISPLAY_DATA_SAPSCRIPT
*&---------------------------------------------------------------------*
*&      Form  CLOSE_END_FORM
*&---------------------------------------------------------------------*
form close_end_form .

  call function 'END_FORM'
    exceptions
      unopened                 = 1
      bad_pageformat_for_print = 2
      spool_error              = 3
      codepage                 = 4
      others                   = 5.
  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
            with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

  call function 'CLOSE_FORM'
    exceptions
      unopened                 = 1
      bad_pageformat_for_print = 2
      send_error               = 3
      spool_error              = 4
      codepage                 = 5
      others                   = 6.
  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
            with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

endform.                    " CLOSE_END_FORM
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA_ADOBEFORM
*&---------------------------------------------------------------------*
form display_data_adobeform using ut_vbrk type zba_vbrk_t
                                  ut_kna1 type zba_kna1_t
                                  ut_adrc type zba_adrc_t
                                  ut_invoice type zba_invoice_t
                                  us_value type zba_s_value.

  data: lv_outputparams type sfpoutputparams,
        lv_fname type rs38l_fnam,
        lv_docparams type sfpdocparams.

  call function 'FP_JOB_OPEN'
    changing
      ie_outputparams = lv_outputparams
    exceptions
      cancel          = 1
      usage_error     = 2
      system_error    = 3
      internal_error  = 4
      others          = 5.
  if sy-subrc <> 0.
    message id sy-msgid type sy-msgty number sy-msgno
            with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  endif.

  try.
      call function 'FP_FUNCTION_MODULE_NAME'
        exporting
          i_name                     = 'ZBA_ADOBE_FORM'
       importing
         e_funcname                 = lv_fname
*   E_INTERFACE_TYPE           =
            .
    catch cx_fp_api_usage .                             "#EC NO_HANDLER
    catch cx_fp_api_repository .                        "#EC NO_HANDLER
    catch cx_fp_api_internal .                          "#EC NO_HANDLER
  endtry.

  lv_docparams-langu = 'E'.

  call function lv_fname
    exporting
      /1bcdwb/docparams = lv_docparams
      gt_vbrk           = ut_vbrk
      gt_invoice        = ut_invoice
      gs_value          = us_value
      gt_adrc           = ut_adrc
      gt_kna1           = ut_kna1
    exceptions
      usage_error       = 1
      system_error      = 2
      internal_error    = 3.
  if sy-subrc <> 0.
    message text-003 type 'E' display like 'S'.
  endif.

  call function 'FP_JOB_CLOSE'
    exceptions
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      others         = 4.
  if sy-subrc <> 0.
    message text-004 type 'E' display like 'S'.
  endif.

endform.                    " DISPLAY_DATA_ADOBEFORM
