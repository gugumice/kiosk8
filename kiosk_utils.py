#!/usr/bin/env python3
''' A module for utility classes and functions. '''

import os
from datetime import datetime
from enum import Enum, auto
from queue import Queue
import subprocess
import logging
import requests
import kiosk_config
from pathlib import Path
from time import sleep
queue_to_gui = Queue()
config = dict()

class TicketPurpose(Enum):
    '''Enum class to represent the purpose of the ticket.'''
    BCR = auto()  # Barcode reader ticket
    NET = auto()  # Request ticket
    PRN = auto()  # Printer ticket
    SYS = auto()  # System ticket
    ERR = auto()  # Error ticket
    AOK = auto()  # OK ticket
    PRG = auto()  # In progress ticket
    INC = auto()  # Incomplete rep ticket
    EOT = auto()  # End of ticket

class Ticket(object):
    """Class to represent a ticket with a type and value."""
    def __init__(self, ticket_type = TicketPurpose, ticket_value:str= None, ticket_display_time:int = 0, ticket_animate_cycles:int = 0):
        self.ticket_type:TicketPurpose = ticket_type
        self.ticket_value:str = ticket_value
        self.ticket_display_time:int = ticket_display_time
        self.ticket_animate_cycles:int = ticket_animate_cycles

def send_ticket(ticket_value:str = None, 
                ticket_type:Ticket=TicketPurpose.SYS, 
                ticket_display_time:int = 0,
                ticket_animate_cycles:int = 0,
                queue_tx:Queue = None):
    """
    Function to send a ticket to the service thread.
    :param value: Value of the ticket
    :param : Type of the ticket (TicketPurpose)
    :param ticket_display_time: Time in milliseconds to display the ticket
    :param ticket_animate_cycles: For how many GIF cycles to display ticket
    """
    ticket = Ticket(ticket_type=ticket_type,
                    ticket_value=ticket_value,
                    ticket_display_time=ticket_display_time,
                    ticket_animate_cycles=ticket_animate_cycles)
    
    queue_tx.put(ticket)
    logging.info(f"Ticket sent: <{ticket.ticket_value}> of type <{ticket.ticket_type}>")

def host_info() -> list:
    """ 
    Function to get the IP address and hostname.
    Returns a list of IP address and hostname or None if it fails.
    """
    try:
        return([subprocess.check_output(['hostname', '-I']).decode('utf-8').strip(),
                subprocess.check_output(['hostname', '-f']).decode('utf-8').strip()]) 
    except:
        return(None)
    
def get_numpages_from_pdf(f:str) -> int:
    result = subprocess.run(
    ['bash', '-c', 'pdfinfo {} | grep "Pages:"'.format(f)],
    capture_output=True, text=True
    )
    # Store the result in a variable
    pages_info = result.stdout.strip()
    return(int(pages_info[6:].strip()))
    
def speak_status(f, background = True)-> None:
    '''
    Speak status messages
    '''
    if background:
        try:
            os.popen('aplay -q {} 2>&1'.format(f))
        except Exception:
            logging.error(f"Error playing sound: {f}, {e}")
    else:
        try:
            os.system('aplay -q {} 2>&1'.format(f))
        except Exception as e:
            logging.error(f"Error playing sound: {f}, {e}")

def set_brightness(level: int, path:str = "/sys/class/backlight") -> None:
    backlight_base = Path(path)
    devices = list(backlight_base.glob("*"))
    if not devices:
        raise RuntimeError(f"No backlight device found on {backlight_base}")

    errors = []
    successes = 0

    for device in devices:
        try:
            max_brightness = int((device / "max_brightness").read_text().strip())
            safe_level = max(0, min(level, max_brightness))
            with open(device / "brightness", "w") as f:
                f.write(str(safe_level))
            successes += 1
            logging.debug(f"Set brightness to {safe_level} on {device}")

        except Exception as e:
            errors.append((str(device), str(e)))

    if successes == 0:
        logging.error("Failed to set brightness on all devices: %s", errors)
        raise RuntimeError(f"Failed to set brightness on all devices: {errors}")

    if errors:
        logging.debug("Some backlight devices failed, but brightness was set: %s", errors)


def set_display(state: str) -> None:
    """
    Control X11 screen blanking.

    Args:
        state: "on" or "off"

    on  -> DISPLAY=:0 xset s reset
    off -> DISPLAY=:0 xset s activate
    """

    env = os.environ.copy()
    env["DISPLAY"] = ":0"

    # Uncomment if needed when running outside the X session
    # env["XAUTHORITY"] = "/home/pi/.Xauthority"

    if state.lower() == "on":
        cmd = ["xset", "s", "reset"]
    elif state.lower() == "off":
        cmd = ["xset", "s", "activate"]
    else:
        raise ValueError("state must be 'on' or 'off'")

    subprocess.run(
        cmd,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )

def host_connection_ok(url) -> None:
    '''
    Test connection to host
    '''
    try:
        #requests.head(url,timeout=10)
        r = requests.get(url, timeout=10)
        return(r.text.strip() == 'OK')
    except requests.ConnectionError:
        return(False)
    
def is_working_time(now:str = None, start:str='7:30', end:str='19:00', workdays:tuple=(0, 1, 2, 3, 4)):
    now = datetime.now() if now is None else datetime.strptime(now, "%H:%M").time()
    # Convert strings to time objects
    start_time = datetime.strptime(start, "%H:%M").time()
    end_time = datetime.strptime(end, "%H:%M").time()

    return (now.weekday() in workdays) and (start_time <= now.time() <= end_time)

class WatchDog(object):
    def __init__(self, wd_device:str = '/dev/watchdog'):
        try:
            self._wd = open(wd_device, "w")
        except Exception as e:
            logging.error('Error opening {}: {}'.format(wd_device, e))
            return(None)
        
    def pat(self):
        try:
            print('1',file = self._wd, flush = True)
            # print('.', end='', flush=True) 
            return(True)
        except:
            return(False)

    def stop(self):
        try:
            print('V',file = self._wd, flush = True)
            return(True)
        except:
            return(False)
def main():
    config = kiosk_config.read_config(os.path.join(os.getcwd(),'kiosk.ini'))
    #speak_status('assets/lang_LAT.wav', background=True)
    #speak_status(os.path.join(config['assets_loader'], 'start_print{}.wav'.format('LAT')), background=False)
    set_brightness(255, config)
    sleep(5)
    set_brightness(100, config)
    sleep(5)
    set_brightness(0, config)


    # w = config['watchdog_device']
    # print(w)
    # wdObj = WatchDog(w)
    # for i in range(0,20):
    #     if wdObj:
    #         print(wdObj.pat())
    #     sleep(1)
    # wdObj.stop()
    # print('stopped')
if __name__ == '__main__':
    main()
