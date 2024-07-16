module Hello2

    implicit none

    public :: msgnumber2
    public :: print_message_2

    integer :: msgnumber2 = 2
    integer :: dummy2 = 0

    contains

    subroutine print_message_2

        print *, 'Hello from module ', msgnumber2

    endsubroutine print_message_2

endmodule Hello2
