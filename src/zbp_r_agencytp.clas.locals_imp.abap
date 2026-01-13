*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lhc_/dmo/agency DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS zzAssignType FOR MODIFY
      IMPORTING keys FOR ACTION /DMO/Agency~zzAssignType RESULT result.
    METHODS zzValidateAgencyFee FOR VALIDATE ON SAVE
      IMPORTING keys FOR /DMO/Agency~zzValidateAgencyFee.
    METHODS zzDeterminateVAT FOR DETERMINE ON MODIFY
      IMPORTING keys FOR /DMO/Agency~zzDeterminateVAT.

    CONSTANTS validate_fee TYPE string VALUE 'VALIDATE_FEE'.

ENDCLASS.

CLASS lhc_/dmo/agency IMPLEMENTATION.

  METHOD zzAssignType.
* Leo el nodo de la INTERFACE, lo que me da un mejor rendimiento
    READ ENTITIES OF /DMO/I_AgencyTP IN LOCAL MODE
    ENTITY /DMO/Agency
    FIELDS ( CountryCode zzagncytypzag  )
    WITH CORRESPONDING #( keys )
    RESULT DATA(agencies).

    LOOP AT agencies ASSIGNING FIELD-SYMBOL(<agency>).

      CASE <agency>-CountryCode.
        WHEN 'US'.
          <agency>-zzagncytypzag = 'M'.
        WHEN OTHERS.
          <agency>-zzagncytypzag = 'O'.
      ENDCASE.

    ENDLOOP.
    MODIFY ENTITIES OF /DMO/I_AgencyTP IN LOCAL MODE
    ENTITY /DMO/Agency
    UPDATE FIELDS (  zzagncytypzag  )
    WITH CORRESPONDING #( agencies ).

    result = VALUE #( FOR agency IN agencies ( %tky   = agency-%tky
                                               %param = agency ) ).

  ENDMETHOD.

  METHOD zzValidateAgencyFee.

    READ ENTITIES OF /DMO/I_AgencyTP IN LOCAL MODE
     ENTITY /DMO/Agency
     FIELDS ( zzagfeezag  )
     WITH CORRESPONDING #( keys )
     RESULT DATA(agencies).


    LOOP AT agencies INTO DATA(agency).

      APPEND VALUE #( %tky        = agency-%tky
                      %state_area = validate_fee ) TO reported-/dmo/agency.

      IF NOT ( agency-zzagfeezag GT 0 AND agency-zzagfeezag LT 100 ).

        APPEND VALUE #( %tky  = agency-%tky  ) TO failed-/dmo/agency.

        APPEND VALUE #( %tky                = agency-%tky
                        %state_area         = validate_fee
                        %msg                = NEW zcm_agency( textid = zcm_agency=>invalid_fee
                                                              severity = if_abap_behv_message=>severity-error )
                        %element-zzagfeezag = if_abap_behv=>mk-on  ) TO reported-/dmo/agency.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD zzDeterminateVAT.

    DATA agencies_update TYPE TABLE FOR UPDATE /DMO/I_AgencyTP.

    READ ENTITIES OF /DMO/I_AgencyTP IN LOCAL MODE
       ENTITY /DMO/Agency
       FIELDS ( CountryCode zzvatzag )
       WITH CORRESPONDING #( keys )
       RESULT DATA(agencies).


    LOOP AT agencies INTO DATA(agency).

      IF agency-CountryCode IS NOT INITIAL.

        APPEND INITIAL LINE TO agencies_update ASSIGNING FIELD-SYMBOL(<agency_update>).

        <agency_update>-%tky = agency-%tky.

        CASE agency-CountryCode.
          WHEN 'US'.
            agency-zzvatzag = 15.
          WHEN OTHERS.
            agency-zzvatzag = 21.
        ENDCASE.
        <agency_update>-zzvatzag = agency-zzvatzag.
      ENDIF.

    ENDLOOP.

    MODIFY ENTITIES OF /DMO/I_AgencyTP IN LOCAL MODE
    ENTITY /DMO/Agency
    UPDATE FIELDS ( zzvatzag )
    WITH agencies_update.

  ENDMETHOD.

ENDCLASS.
