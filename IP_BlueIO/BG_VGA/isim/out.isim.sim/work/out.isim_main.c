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
    worx_mktbtilegraphiccard_m_16541823861846354283_2073120511_init();
    worx_mktbtilegraphiccard_m_13649925861754422752_3054949844_init();
    worx_mktbtilegraphiccard_m_13649925861754422752_4254559545_init();
    worx_mktbtilegraphiccard_m_13649925861754422752_3421633845_init();
    worx_mktbtilegraphiccard_m_12589189402509152137_4212489043_init();
    worx_mktbtilegraphiccard_m_13649925861754422752_0142368599_init();
    worx_mktbtilegraphiccard_m_15067786906752832389_2754964831_init();
    worx_mktbtilegraphiccard_m_10228239250807422521_1349347590_init();
    worx_mktbtilegraphiccard_m_11814650570218390564_0286164271_init();


    xsi_register_tops("worx_mktbtilegraphiccard_m_16541823861846354283_2073120511");
    xsi_register_tops("worx_mktbtilegraphiccard_m_11814650570218390564_0286164271");


    return xsi_run_simulation(argc, argv);

}
