class ZCL_SNAKE definition
  public
  inheriting from ZCL_EEZZ_TABLE
  final
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !EVENT type STRING default '' .
  methods GET_SEGMENTS
    importing
      !EVENT type STRING default ''
    returning
      value(RT_TABLE) type ref to ZCL_EEZZ_TABLE .
  methods RESET
    importing
      !EVENT type STRING default '' .
protected section.
private section.

  data MT_DIRECTION type I .
  data MT_SEGMENTS type ref to ZTTY_SEGMENTS .
ENDCLASS.



CLASS ZCL_SNAKE IMPLEMENTATION.


  method CONSTRUCTOR.
    super->constructor( ).
    mt_segments = new ztty_segments( ).

    reset( event ).
  endmethod.


  method GET_SEGMENTS.

*   data table direction
*   10 0 / 0 10 / -10 0 / 0 -10
    types: begin of ty_str_direction,
      cx type i,
      cy type i,
    end of ty_str_direction.

    types:
      tty_direction  type table of ty_str_direction with key cx cy initial size 0.

    data xstr_direction type ty_str_direction.
    data xl_direction   type i.

*   evaluate evemts, which come fro UI
    case event.
      when 'left'.
        mt_direction = ( mt_direction + 3 )  mod 4.
      when 'right'.
        mt_direction = ( mt_direction + 1 )  mod 4.
    endcase.

    xl_direction = mt_direction + 1.


*   evaluate the new direction:
    data xtbl_direction type tty_direction.
    xtbl_direction = value #(
     ( cx =  10 cy =   0 )
     ( cx =   0 cy =  10 )
     ( cx = -10 cy =   0 )
     ( cx =   0 cy = -10 )
    ).

    read table xtbl_direction index xl_direction into xstr_direction.

*   save and delete last element
    data(x_lines) = lines( mt_segments->* ).
    read table mt_segments->* index x_lines into data(x_tail).
    delete mt_segments->* index x_lines.

*   get first element and creatae new head
    read table mt_segments->* index 2 into data(x_head).
    x_tail-c_posx = x_head-c_posx + xstr_direction-cx.
    x_tail-c_posy = x_head-c_posy + xstr_direction-cy.

*   check if we can insert an element
*   dublicate key:
*      if food: fouod become segment and create new food
*      else   : terminate game
    try.
      loop at mt_segments->* into data(x_double_key) where c_posx = x_tail-c_posx and c_posy = x_tail-c_posy.
         raise exception type CX_SY_ITAB_DUPLICATE_KEY.
      endloop.

      insert x_tail into mt_segments->* index 2.
    catch CX_SY_ITAB_DUPLICATE_KEY.
      FIELD-SYMBOLS <x_food> like line of mt_segments->*.
      read table mt_segments->* index 1 assigning <x_food>.
      if x_tail-c_posx = <x_food>-c_posx and x_tail-c_posy = <x_food>-c_posy.
        insert x_tail into mt_segments->* index 2.
        <x_food>-c_type = 0.
*       find a new random food position:
        x_tail-c_posx = ( x_tail-c_posx + 20 ).
        x_tail-c_posy = ( x_tail-c_posy + 20 ).
        x_tail-c_type = 1.
        insert x_tail into mt_segments->* index 1.
      endif.
    endtry.

*   check if we have to terminate and print some message
    if x_tail-c_posx < 1 or x_tail-c_posx > 900 or x_tail-c_posy < 1 or x_tail-c_posy > 900.
      clear mt_segments->*.
      zcl_eezz_message=>add( iv_key = 'status' iv_message = value #( c_msgtext = |game over| c_msgcls  = 'zcl_eezz_snake'  c_msgnum = 0 ) ).
    endif.


    data(x_eezz_table) = new zcl_eezz_table( iv_table = mt_segments ).
    rt_table = cast #( x_eezz_table ).
  endmethod.


  method RESET.


    mt_segments->* = value #(
        ( c_posx =  80  c_posy = 80   c_type = 1 )
        ( c_posx = 100  c_posy = 50   c_type = 0 )
        ( c_posx =  90  c_posy = 50   c_type = 0 )
        ( c_posx =  80  c_posy = 50   c_type = 0 )
        ( c_posx =  70  c_posy = 50   c_type = 0 )
    ).
    mt_direction  = 0.
  endmethod.
ENDCLASS.
