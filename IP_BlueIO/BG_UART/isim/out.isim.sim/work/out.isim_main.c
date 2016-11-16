/**********************************************************************/
/*   ____  ____                                                       */
/*  /   /\/   /                                                       */
/* /___/  \  /                                                        */
/* \   \   \/                                                       */
/*  \   \        Copyright (c) 2003-2009 Xilinx, Inc.                */
/*  /   /          All Right Reserved.                                 */
/* /---/   /\                                                         */
/* \   \  /  \                                                      */
/*  \___\/\___\                                                    */
/***********************************************************************/

#include "xsi.h"

struct XSI_INFO xsi_info;



int main(int argc, char **argv)
{
    xsi_init_design(argc, argv);
    xsi_register_info(&xsi_info);

    xsi_register_min_prec_unit(-12);
    worx_mktbscuart_driver_m_16541823861846354283_2073120511_init();
    worx_mktbscuart_driver_m_13649925861754422752_1249218312_init();
    worx_mktbscuart_driver_m_04442082693589477573_2756856867_init();
    worx_mktbscuart_driver_m_16641042268883733971_2659506311_init();
    worx_mktbscuart_driver_m_07554407054823422585_1514446708_init();
    worx_mktbscuart_driver_m_11814650570218390564_0286164271_init();


    xsi_register_tops("worx_mktbscuart_driver_m_16541823861846354283_2073120511");
    xsi_register_tops("worx_mktbscuart_driver_m_11814650570218390564_0286164271");


    return xsi_run_simulation(argc, argv);

}
