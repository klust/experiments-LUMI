module Hello1

    implicit none

    public :: msgnumber1
    public :: print_message_1

    integer :: msgnumber1 = 1

    contains

    subroutine print_message_1

        print *, 'Hello from module ', msgnumber1

    endsubroutine print_message_1

endmodule Hello1
