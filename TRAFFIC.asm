   
#start=traffic_lights.exe#    port 4
#start=stepper_motor.exe#     port 7
#start=led_display.exe#       port 199   
   
   
;Travis Caro
;CIS 253 
;
;TRAFFIC
;
;ALGORITHM:
;
;   





include 'emu8086.inc'

org 100h

jmp Code

;Data


;Traffic Data

;                       FEDC_BA98_7654_3210                
North_To_South      dw  0000_0011_0000_1001b
North_To_South_Y    dw  0000_0010_1000_1001b

East_To_West        dw  0000_0010_0110_0001b 
East_To_West_Y      dw  0000_0010_0101_0001b
               
South_To_North      dw  0000_0010_0100_1100b 
South_To_North_Y    dw  0000_0010_0100_1010b

West_To_East        dw  0000_1000_0100_1001b
West_To_East_Y      dw  0000_0100_0100_1001b     

Sit_End = $

All_Red         dw  0000_0010_0100_1001b           
             
             
             
;Stepper Data

                    ;Half Step rotation 11.25 degrees
Clockwise       db  0000_0110,0000_0100,0000_0011,0000_0010             
C_Clockwise     db  0000_0011,0000_0001,0000_0110,0000_0010

change_dir = 8      ;Each half step of array = 11.25 degrees, therefore full cycle would be 45 degrees
                    ; 45 * 8 = 360       
change_light = 4    ;This would be half rotation to change lights so that can switch to caution light


Temp            db  0             
LED_Count       db  0             
             
             
     
Code: 

;Initial Setup for Stepper
lea di, Clockwise
mov cx, 0 
mov bx, 0 


;Initial Setup for Traffic
lea si, North_To_South


call Traffic     
     
                 
Traffic PROC
    
    ;Start traffic on all red lights to setup
    mov ax, All_Red 
    out 4, ax
      
    Next:
    
        ;Output current situation
        mov ax, [si]
        out 4, ax
        
        ;Call Stepper function to wait before changing
        call Stepper
        
        
        ;Check for how to step through situations   
           
        add si, 2   ;Step to next situation
        cmp si, Sit_End
        jb Next
        
        ;If through all situations, reset and go again
        lea si, North_To_South
        jmp Next   
    
ret
Traffic ENDP    


Stepper PROC
        
    ;Setup pointer to direction sequence, setup counter, and setup index counter
          
    
    Step:
    StepWait:
    
        in al, 7
        test al, 1000_0000b ;Performs AND operation on AL to set flag (note doesn't actually AND AL)
            
        je StepWait
        
         
        mov al, [di][bx]
        out 7, al
        inc bx  ;Increment Index
        cmp bx, 4
        
        jl Step  
        
        ;Reset Index -> Step complete
        ;Bump counter and check direction
        mov bx, 0
        inc cx 
        
        ;Compare cx to see if half turn has been performed to change light
        cmp cx, change_light
        je LightChange
        
        cmp cx, change_dir
        
        jl Step
        
        mov cx, 0
        add di, 4   ;Cycle finish and direction change. Look ahead to see which direction to change to
        
        ;If 4 ahead is Counter clockwise array, then switch to counterclockwise, otherwise counterclockwise just finished
        ;Then switch back to clockwise       
        mov dl, C_Clockwise
        cmp [di], dl                     
        je CountClockwise
        
        lea di, Clockwise
        jmp LightChange
        
        CountClockwise:
        call LED
                
        LightChange:                                  
ret
Stepper ENDP
            
            
LED PROC
    
    ;LED (Optional)
    mov Temp, al
    mov al, LED_Count 
     
    inc al
    out 199,al 
    
    mov LED_Count, al
    mov al, Temp
    
                          
ret
LED ENDP            
            
            
ret
END

DEFINE_PRINT_NUM
DEFINE_PRINT_NUM_UNS
DEFINE_GET_STRING 
DEFINE_PRINT_STRING
DEFINE_SCAN_NUM
DEFINE_CLEAR_SCREEN
DEFINE_PTHIS

