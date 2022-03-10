*/---------------------------------------------------------------------\
*| Copyright 2017 Arvio Bjedi                                          |
*|                                                                     |
*| Licensed under the Apache License, Version 2.0 (the "License");     |
*| you may not use this file except in compliance with the License.    |
*| You may obtain a copy of the License at                             |
*|                                                                     |
*|     http://www.apache.org/licenses/LICENSE-2.0                      |
*|                                                                     |
*| Unless required by applicable law or agreed to in writing, software |
*| distributed under the License is distributed on an "AS IS" BASIS,   |
*| WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or     |
*| implied.                                                            |
*| See the License for the specific language governing permissions and |
*| limitations under the License.                                      |
*\---------------------------------------------------------------------/
REPORT zab_print_forms.

*&---------------------------------------------------------------------*
*& Selection screen
*&---------------------------------------------------------------------*
PARAMETERS: p_vbeln TYPE vbrk-vbeln OBLIGATORY.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_smart RADIOBUTTON GROUP r1,
              p_sapsc RADIOBUTTON GROUP r1,
              p_adobe RADIOBUTTON GROUP r1.
SELECTION-SCREEN END OF BLOCK b1.

*&---------------------------------------------------------------------*
*& Start-of-selection
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  DATA: gt_vbrk    TYPE zba_vbrk_t,
        gt_adrc    TYPE zba_adrc_t,
        gt_kna1    TYPE zba_kna1_t,
        gt_invoice TYPE zba_invoice_t,
        gs_value   TYPE zba_s_value,
        gs_vbrk    TYPE zba_s_vbrk,
        gs_kna1    TYPE zba_s_kna1,
        gs_invoice TYPE zba_s_invoice,
        gs_adrc    TYPE zba_s_adrc,
        gs_row     TYPE string,                             "#EC NEEDED
        gt_row     TYPE TABLE OF string,
        gt_rows    TYPE TABLE OF string.

  PERFORM selection_vbrk CHANGING gt_vbrk .
  PERFORM selection_kna1 CHANGING gt_kna1 .
  PERFORM selection_adrc USING gt_vbrk CHANGING gt_adrc .

  IF p_smart IS NOT INITIAL.
    PERFORM display_select TABLES gt_vbrk gt_kna1 gt_adrc
                           CHANGING gt_invoice gs_value.
    PERFORM display_data_smartform USING gt_vbrk gt_kna1 gt_adrc
                                         gt_invoice gs_value.
  ENDIF.

  IF p_sapsc IS NOT INITIAL.
    PERFORM open_start_form.
    PERFORM display_data_sapscript .
    PERFORM close_end_form.
  ENDIF.

  IF p_adobe IS NOT INITIAL.
    PERFORM display_select TABLES gt_vbrk gt_kna1 gt_adrc
                          CHANGING gt_invoice gs_value.
    PERFORM display_data_adobeform USING gt_vbrk gt_kna1 gt_adrc
                                         gt_invoice gs_value.
  ENDIF.
*&---------------------------------------------------------------------*
*&      Form  SELECTION
*&---------------------------------------------------------------------*
FORM selection_vbrk CHANGING ct_vbrk TYPE zba_vbrk_t.

  SELECT vbrk~vbeln vbrk~fkdat vbrp~posnr vbrp~arktx vbrp~matnr
         vbrp~vrkme vbrp~fkimg vbrp~netwr vbrp~mwsbp tvzbt~vtext
         vbrk~zterm tinct~bezei vbrk~inco1 vbrk~inco2 vbrk~bukrs
    FROM vbrk JOIN vbrp ON vbrp~vbeln = vbrk~vbeln
              JOIN tinct ON tinct~inco1 = vbrk~inco1
              JOIN tvzbt ON tvzbt~zterm = vbrk~zterm
    INTO CORRESPONDING FIELDS OF TABLE ct_vbrk
    WHERE vbrk~vbeln = p_vbeln
      AND tinct~spras = 'E'
      AND tvzbt~spras = 'E'.

ENDFORM.                    " SELECTION
*&---------------------------------------------------------------------*
*&      Form  SELECTION_KNA1
*&---------------------------------------------------------------------*
FORM selection_kna1 CHANGING ct_kna1 TYPE zba_kna1_t.

  SELECT kna1~name1 kna1~stceg kna1~stras kna1~ort01 t005t~landx
         kna1~telf1 AS telef1
    FROM kna1 JOIN vbrk ON kna1~kunnr = vbrk~kunrg
              JOIN t001 ON vbrk~bukrs = t001~bukrs
              JOIN t005t ON t001~land1 = t005t~land1
    INTO CORRESPONDING FIELDS OF TABLE ct_kna1
    WHERE vbrk~vbeln = p_vbeln
    AND t005t~spras = 'E'.

ENDFORM.                    " SELECTION_KNA1
*&---------------------------------------------------------------------*
*&      Form  SELECTION_ADRC
*&---------------------------------------------------------------------*
FORM selection_adrc  USING    ut_vbrk TYPE zba_vbrk_t
                     CHANGING ct_adrc TYPE zba_adrc_t.
  IF ut_vbrk IS NOT INITIAL.
    SELECT adrc~name1 adrc~street adrc~house_num1 adrc~city1
           t001~stceg t001~bukrs t005t~landx
      FROM t001 JOIN adrc ON adrc~addrnumber = t001~adrnr
                JOIN kna1 ON kna1~stceg = t001~stceg
                JOIN t005t ON t001~land1 = t005t~land1
      INTO CORRESPONDING FIELDS OF TABLE ct_adrc
      FOR ALL ENTRIES IN ut_vbrk
      WHERE t001~bukrs = ut_vbrk-bukrs
      AND t005t~spras = 'E'.
  ENDIF.
ENDFORM.                    " SELECTION_ADRC
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_SELECT
*&---------------------------------------------------------------------*
FORM display_select TABLES tt_vbrk TYPE zba_vbrk_t
                           tt_kna1 TYPE zba_kna1_t
                           tt_adrc TYPE zba_adrc_t
                  CHANGING ct_invoice TYPE zba_invoice_t
                           cs_value TYPE zba_s_value.

  DATA: ls_vbrk    TYPE zba_s_vbrk,
        ls_invoice TYPE zba_s_invoice,
        ls_kna1    TYPE zba_s_kna1,
        ls_adrc    TYPE zba_s_adrc,
        lt_line    TYPE STANDARD TABLE OF tline,
        ls_line    TYPE tline,
        lv_name    TYPE thead-tdname,
        lv_text    TYPE tline-tdline.

  LOOP AT tt_vbrk INTO ls_vbrk.
    CONCATENATE ls_vbrk-vbeln ls_vbrk-posnr INTO lv_name.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        client                  = sy-mandt
        id                      = '0002'
        language                = 'E'
        name                    = lv_name
        object                  = 'VBBP'
      TABLES
        lines                   = lt_line
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    LOOP AT lt_line INTO ls_line.
      lv_text = ls_line-tdline.
    ENDLOOP.
    ls_vbrk-text = lv_text.
    MODIFY tt_vbrk FROM ls_vbrk.
  ENDLOOP.
  LOOP AT tt_vbrk INTO ls_vbrk.
    CLEAR ls_invoice.
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

    CLEAR ls_kna1.
    READ TABLE tt_kna1 INTO ls_kna1 WITH KEY kunnr  = ls_vbrk-kunrg.
    IF sy-subrc = 0.
      ls_invoice-name1 = ls_kna1-name1.
      ls_invoice-stceg = ls_kna1-stceg.
      ls_invoice-stras = ls_kna1-stras.
      ls_invoice-ort01 = ls_kna1-ort01.
      ls_invoice-landx = ls_kna1-landx.
      ls_invoice-telef1 = ls_kna1-telef1.

      CLEAR ls_adrc.
      READ TABLE tt_adrc INTO ls_adrc WITH KEY bukrs = ls_vbrk-bukrs.
      IF sy-subrc = 0.
        ls_invoice-name1_1 = ls_adrc-name1.
        ls_invoice-street = ls_adrc-street.
        ls_invoice-house_num1 = ls_adrc-house_num1.
        ls_invoice-city1 = ls_adrc-city1.
        ls_invoice-landx_1 = ls_adrc-landx.
        ls_invoice-stceg_1 = ls_adrc-stceg.

      ENDIF.
    ENDIF.
    cs_value-gv_tot1 = cs_value-gv_tot1 + ls_vbrk-netwr.
    cs_value-gv_tot2 = cs_value-gv_tot2 + ls_vbrk-mwsbp.

    SHIFT ls_invoice-posnr LEFT DELETING LEADING '0'.
    APPEND ls_invoice TO ct_invoice.

  ENDLOOP.
ENDFORM.                    " DISPLAY_SELECT
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA_SF
*&---------------------------------------------------------------------*
FORM display_data_smartform USING ut_vbrk TYPE zba_vbrk_t
                                  ut_kna1 TYPE zba_kna1_t
                                  ut_adrc TYPE zba_adrc_t
                                  ut_invoice TYPE zba_invoice_t
                                  us_value TYPE zba_s_value.
  DATA: lv_fname TYPE rs38l_fnam.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname           = 'ZBA_SMARTFORM'
    IMPORTING
      fm_name            = lv_fname
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION lv_fname
    EXPORTING
      gt_vbrk          = ut_vbrk
      gt_invoice       = ut_invoice
      gs_value         = us_value
      gt_adrc          = ut_adrc
      gt_kna1          = ut_kna1
    EXCEPTIONS
      formatting_error = 1
      internal_error   = 2
      send_error       = 3
      user_canceled    = 4
      OTHERS           = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " DISPLAY_DATA
*&---------------------------------------------------------------------*
*&      Form  OPEN_START_FORM
*&---------------------------------------------------------------------*
FORM open_start_form .

  CALL FUNCTION 'OPEN_FORM'
    EXPORTING
      form                        = 'ZBA_FORM_SCRIPT'
    EXCEPTIONS
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
      OTHERS                      = 12.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION 'START_FORM'
    EXPORTING
      form        = 'ZBA_FORM_SCRIPT'
      language    = 'E'
      startpage   = 'PAGE1'
      program     = 'ZAB_PRINT_FORMS'
    EXCEPTIONS
      form        = 1
      format      = 2
      unended     = 3
      unopened    = 4
      unused      = 5
      spool_error = 6
      codepage    = 7
      OTHERS      = 8.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
*     ELEMENT                  = ' '
      window                   = 'GRAPH1'
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'BOXBOX'
      window                   = 'WINDOW1'
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'HEAD'
      window                   = 'MAIN'
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'TABLE'
      window                   = 'MAIN'
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'ADDR'
      window                   = 'ADDR'
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.
  IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'CUS'
      window                   = 'CUSTOMER'
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.
  IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'INV'
      window                   = 'INBOLD'
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'INVO'
      window                   = 'IN_NR_DT'
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'PAG'
      window                   = 'PAGENR'
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION 'WRITE_FORM'
    EXPORTING
      element                  = 'FOOTER'
      window                   = 'TOTAL'
    EXCEPTIONS
      element                  = 1
      function                 = 2
      type                     = 3
      unopened                 = 4
      unstarted                = 5
      window                   = 6
      bad_pageformat_for_print = 7
      spool_error              = 8
      codepage                 = 9
      OTHERS                   = 10.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " OPEN_START_FORM
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA_SAPSCRIPT
*&---------------------------------------------------------------------*
FORM display_data_sapscript .

  DATA: lt_line TYPE STANDARD TABLE OF tline,
        ls_line TYPE tline,
        lv_name TYPE thead-tdname,
        lv_text TYPE tline-tdline.

  LOOP AT gt_vbrk INTO gs_vbrk .
    CONCATENATE gs_vbrk-vbeln gs_vbrk-posnr INTO lv_name.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        client                  = '800'
        id                      = '0002'
        language                = 'E'
        name                    = lv_name
        object                  = 'VBBP'
      TABLES
        lines                   = lt_line
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.
    IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CLEAR ls_line.
    LOOP AT lt_line INTO ls_line.
      lv_text = ls_line-tdline.


      REFRESH gt_rows.
      CALL FUNCTION 'RKD_WORD_WRAP'
        EXPORTING
          textline            = lv_text
          outputlen           = 35
        TABLES
          out_lines           = gt_rows
        EXCEPTIONS
          outputlen_too_large = 1
          OTHERS              = 2.
      IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      APPEND LINES OF gt_rows TO gt_row.
    ENDLOOP.

    CLEAR gs_invoice.
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

    CLEAR gs_kna1.
    READ TABLE gt_kna1 INTO gs_kna1 WITH KEY kunnr  = gs_vbrk-kunrg.
    IF sy-subrc = 0.
      gs_invoice-name1 = gs_kna1-name1.
      gs_invoice-stceg = gs_kna1-stceg.
      gs_invoice-stras = gs_kna1-stras.
      gs_invoice-ort01 = gs_kna1-ort01.
      gs_invoice-landx = gs_kna1-landx.
      gs_invoice-telef1 = gs_kna1-telef1.

      CLEAR gs_adrc.
      READ TABLE gt_adrc INTO gs_adrc WITH KEY bukrs = gs_vbrk-bukrs.
      IF sy-subrc = 0.
        gs_invoice-name1_1 = gs_adrc-name1.
        gs_invoice-street = gs_adrc-street.
        gs_invoice-house_num1 = gs_adrc-house_num1.
        gs_invoice-city1 = gs_adrc-city1.
        gs_invoice-landx_1 = gs_adrc-landx.
        gs_invoice-stceg_1 = gs_adrc-stceg.

      ENDIF.
    ENDIF.
    gs_value-gv_tot1 = gs_value-gv_tot1 + gs_vbrk-netwr.
    gs_value-gv_tot2 = gs_value-gv_tot2 + gs_vbrk-mwsbp.
    APPEND gs_invoice TO gt_invoice.

    CALL FUNCTION 'WRITE_FORM'
      EXPORTING
        element                  = 'MATERIALS'
        type                     = 'BODY'
        window                   = 'MAIN'
      EXCEPTIONS
        element                  = 1
        function                 = 2
        type                     = 3
        unopened                 = 4
        unstarted                = 5
        window                   = 6
        bad_pageformat_for_print = 7
        spool_error              = 8
        codepage                 = 9
        OTHERS                   = 10.
    IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    LOOP AT gt_row INTO gs_row.
      CALL FUNCTION 'WRITE_FORM'
        EXPORTING
          element                  = 'DESC'
          type                     = 'BODY'
          window                   = 'MAIN'
        EXCEPTIONS
          element                  = 1
          function                 = 2
          type                     = 3
          unopened                 = 4
          unstarted                = 5
          window                   = 6
          bad_pageformat_for_print = 7
          spool_error              = 8
          codepage                 = 9
          OTHERS                   = 10.
      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " DISPLAY_DATA_SAPSCRIPT
*&---------------------------------------------------------------------*
*&      Form  CLOSE_END_FORM
*&---------------------------------------------------------------------*
FORM close_end_form .

  CALL FUNCTION 'END_FORM'
    EXCEPTIONS
      unopened                 = 1
      bad_pageformat_for_print = 2
      spool_error              = 3
      codepage                 = 4
      OTHERS                   = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL FUNCTION 'CLOSE_FORM'
    EXCEPTIONS
      unopened                 = 1
      bad_pageformat_for_print = 2
      send_error               = 3
      spool_error              = 4
      codepage                 = 5
      OTHERS                   = 6.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " CLOSE_END_FORM
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA_ADOBEFORM
*&---------------------------------------------------------------------*
FORM display_data_adobeform USING ut_vbrk TYPE zba_vbrk_t
                                  ut_kna1 TYPE zba_kna1_t
                                  ut_adrc TYPE zba_adrc_t
                                  ut_invoice TYPE zba_invoice_t
                                  us_value TYPE zba_s_value.

  DATA: lv_outputparams TYPE sfpoutputparams,
        lv_fname        TYPE rs38l_fnam,
        lv_docparams    TYPE sfpdocparams.

  CALL FUNCTION 'FP_JOB_OPEN'
    CHANGING
      ie_outputparams = lv_outputparams
    EXCEPTIONS
      cancel          = 1
      usage_error     = 2
      system_error    = 3
      internal_error  = 4
      OTHERS          = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  TRY.
      CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
        EXPORTING
          i_name     = 'ZBA_ADOBE_FORM'
        IMPORTING
          e_funcname = lv_fname
*         E_INTERFACE_TYPE           =
        .
    CATCH cx_fp_api_usage .                             "#EC NO_HANDLER
    CATCH cx_fp_api_repository .                        "#EC NO_HANDLER
    CATCH cx_fp_api_internal .                          "#EC NO_HANDLER
  ENDTRY.

  lv_docparams-langu = 'E'.

  CALL FUNCTION lv_fname
    EXPORTING
      /1bcdwb/docparams = lv_docparams
      gt_vbrk           = ut_vbrk
      gt_invoice        = ut_invoice
      gs_value          = us_value
      gt_adrc           = ut_adrc
      gt_kna1           = ut_kna1
    EXCEPTIONS
      usage_error       = 1
      system_error      = 2
      internal_error    = 3.
  IF sy-subrc <> 0.
    MESSAGE TEXT-003 TYPE 'E' DISPLAY LIKE 'S'.
  ENDIF.

  CALL FUNCTION 'FP_JOB_CLOSE'
    EXCEPTIONS
      usage_error    = 1
      system_error   = 2
      internal_error = 3
      OTHERS         = 4.
  IF sy-subrc <> 0.
    MESSAGE TEXT-004 TYPE 'E' DISPLAY LIKE 'S'.
  ENDIF.

ENDFORM.                    " DISPLAY_DATA_ADOBEFORM
