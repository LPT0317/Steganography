from pynq import Overlay
from pynq import allocate
from pynq import MMIO
import system.driver as driver
from PIL import Image
import numpy as np
import time
import os
import pathlib
import shutil

"""System information"""
overlay_name = "system"
app_version = "steganography.app_"
driver_version = "dev.582a3ccb.1"
version = "v1.2"

overlay = Overlay('./overlay/' +  overlay_name + '.bit')
cdma = driver.Cdma(overlay)
reg = driver.Register(overlay)

def setup_system():
    secret_path = None
    success = True
    print("Select the operating mode for the Steganography system:")
    print("1. Embedding mode")
    print("2. Extracting mode")
    sel = int(input("Enter mode: "))
    if sel == 1:
        mode = 0
        img_name = input("Enter name of cover image: ")
        secret_name = input("Enter name of secret file: ")
        img_path = "./input/" + img_name
        secret_path = "./input/" + secret_name
        if os.path.isfile(img_path) == False:
            print("[Error] Input file: Cover image is not found")
            success = False
        if os.path.isfile(secret_path) == False:
            print("[Error] Input file: Secret file is not found")
            success = False
    elif sel == 2:
        mode = 1
        img_name = input("Enter name of stego image: ")
        img_path = "./input/" + img_name
        if os.path.isfile(img_path) == False:
            print("[Error] Input file: Cover image is not found")
            success = False
    else:
        print("[Error] Selection is invalid")
    return mode, img_path, secret_path, success, img_name

def load_image(img_path):
    image = Image.open(img_path)
    data = np.array(image)
    return data, image.width, image.height

def load_secret(secret_path):
    secret_file = open(secret_path,"r")
    secret_text = secret_file.read()
    data = np.frombuffer(bytes(secret_text, 'utf-8'), dtype=np.uint8)
    secret_file.close()
    return data

def conv_secret(secret_data):
    data = np.arange(len(secret_data) * 2)
    for i in range(0, len(secret_data)):
        secret_bin = bin(secret_data[i])[2:].zfill(8)
        data[i * 2] = int(secret_bin[0:4], 2)
        data[i * 2 + 1] = int(secret_bin[4:], 2)
    return data

def hw_process(mode, input_size):
    control = mode * 4 + 2
    reg.write(1 * 4, 1)
    reg.write(1 * 4, 0)
    reg.write(2 * 4, input_size)
    reg.write(3 * 4, input_size)
    hw_start = time.time()
    reg.write(1 * 4, control) # start engine
    status = reg.read(0)
    while (status == 0):
        status = reg.read(0)
    hw_end = time.time()
    return (hw_end - hw_start)

def hw_embed(mode, secret_size_pl, image_shape, image_data, secret_data):
    cdma.reset()
    SIZE_OF_BRAM = 5460
    image_buffer = allocate(shape=(image_shape[0],image_shape[1],image_shape[2]), dtype=np.uint8)
    secret_buffer = allocate(shape=(secret_size_pl), dtype=np.uint8)
    image_buffer[:] = image_data
    secret_buffer[:] = secret_data
    total_time = 0
    write_size = secret_size_pl
    i = 0
    print("Perform PL Embed...", end="")
    if write_size <= SIZE_OF_BRAM:
        reg.write(1 * 4, 8)
        cdma.transfer(image_buffer.physical_address, driver.CDMA_BRAM_0, write_size * 6)
        cdma.transfer(secret_buffer.physical_address, driver.CDMA_BRAM_1, write_size)
        process_time = hw_process(mode, write_size)
        reg.write(1 * 4, 8)
        cdma.transfer(driver.CDMA_BRAM_0, image_buffer.physical_address, write_size * 6)
        total_time = total_time + process_time
    else:
        while write_size > SIZE_OF_BRAM:
            reg.write(1 * 4, 8)
            cdma.transfer(image_buffer.physical_address + SIZE_OF_BRAM * 6 * i, driver.CDMA_BRAM_0, SIZE_OF_BRAM * 6)
            cdma.transfer(secret_buffer.physical_address + SIZE_OF_BRAM * i, driver.CDMA_BRAM_1, SIZE_OF_BRAM)
            process_time = hw_process(mode, SIZE_OF_BRAM)
            reg.write(1 * 4, 8)
            cdma.transfer(driver.CDMA_BRAM_0, image_buffer.physical_address + SIZE_OF_BRAM * 6 * i,  SIZE_OF_BRAM * 6)
            total_time = total_time + process_time
            write_size = write_size - SIZE_OF_BRAM
            i = i + 1
        reg.write(1 * 4, 8)
        cdma.transfer(image_buffer.physical_address + SIZE_OF_BRAM * 6 * i, driver.CDMA_BRAM_0, write_size * 6)
        cdma.transfer(secret_buffer.physical_address + SIZE_OF_BRAM * i, driver.CDMA_BRAM_1, write_size)
        process_time = hw_process(mode, write_size)
        reg.write(1 * 4, 8)
        cdma.transfer(driver.CDMA_BRAM_0, image_buffer.physical_address + SIZE_OF_BRAM * 6 * i, write_size * 6)
        total_time = total_time + process_time
    print("Done.")               
    print(f"Number of phase processing: {i + 1}")
    return image_buffer

def hw_extract(mode, image_shape, image_data, image_size):
    cdma.reset()
    SIZE_OF_BRAM = 5460
    max_message_size = image_size // 2
    image_buffer = allocate(shape=(image_shape[0],image_shape[1],image_shape[2]), dtype=np.uint8)
    secret_buffer = allocate(shape=(max_message_size), dtype=np.uint8)
    image_buffer[:] = image_data
    write_size = max_message_size
    total_time = 0
    end_flag = False
    i = 0
    print("Perform PL Extract...", end="")
    if write_size < SIZE_OF_BRAM:
        print("Loading data...")
        reg.write(1 * 4, 8)
        cdma.transfer(image_buffer.physical_address, driver.CDMA_BRAM_0, write_size * 6)
        process_time = hw_process(mode, write_size)
        reg.write(1 * 4, 8)
        cdma.transfer(driver.CDMA_BRAM_1, secret_buffer.physical_address, write_size)
        total_time = total_time + process_time
        end_iteration = np.where(secret_buffer == 35)
        num_end = len(end_iteration[0])
        if num_end >= 2:
            for j in range(1, num_end):
                if end_iteration[0][j] == end_iteration[0][j - 1] + 1:
                    secret_buffer = np.resize(secret_buffer, end_iteration[0][j] + 1)
                    break
    else:
        while write_size > SIZE_OF_BRAM:
            reg.write(1 * 4, 8)
            cdma.transfer(image_buffer.physical_address + SIZE_OF_BRAM * 6 * i, driver.CDMA_BRAM_0, SIZE_OF_BRAM * 6)
            process_time = hw_process(mode, SIZE_OF_BRAM)
            reg.write(1 * 4, 8)
            cdma.transfer(driver.CDMA_BRAM_1, secret_buffer.physical_address + SIZE_OF_BRAM * i, SIZE_OF_BRAM)
            total_time = total_time + process_time
            write_size = write_size - SIZE_OF_BRAM
            i = i + 1
            end_iteration = np.where(secret_buffer == 35)
            num_end = len(end_iteration[0])
            if num_end >= 2:
                for j in range(1, num_end):
                    if end_iteration[0][j] == end_iteration[0][j - 1] + 1:
                        end_flag = True
                        secret_buffer = np.resize(secret_buffer, end_iteration[0][j] + 1)
                        break    
            if end_flag:
                break
        if not end_flag:
            reg.write(1 * 4, 8)
            cdma.transfer(image_buffer.physical_address + SIZE_OF_BRAM * 6 * i, driver.CDMA_BRAM_0, write_size * 6)
            process_time = hw_process(mode, write_size)
            reg.write(1 * 4, 8)
            cdma.transfer(driver.CDMA_BRAM_1, secret_buffer.physical_address + SIZE_OF_BRAM * i, write_size)
            total_time = total_time + process_time
            end_iteration = np.where(secret_buffer == 35)
            num_end = len(end_iteration[0])
            if num_end >= 2:
                for j in range(1, num_end):
                    if end_iteration[0][j] == end_iteration[0][j - 1] + 1:
                        end_flag = True
                        secret_buffer = np.resize(secret_buffer, end_iteration[0][j] + 1)
                        break
    print("Done.")                
    print(f"Number of phase processing: {i + 1}")
    return secret_buffer

def main():
    print("+---------------------------------------------+")
    print("|    Welcome to hardware Steganography Demo   |")
    print("+---------------------------------------------+")
    print(f"|    App version   : {app_version}{version}   |")
    print("|    Driver version: " + driver_version + "           |")
    print("+---------------------------------------------+")
    print()
    
    print("Config hardware...")
    print("Hardware version: " + version)
    print()
    
    print("Type 'help' for instructions")
    print()
    
    mode = -1
    img_path = ""
    img_name = ""
    secret_path = ""
    success = False
    image_data = None
    secret_data = None
    secret_byte = None
    debug = False
    image_shape = [0, 0, 3]
    image_size = 0
    secret_size_ps = 0
    secret_size_pl = 0
    app_start = time.time()
    cmd = input(">>> ")
    while (cmd != "exit"):
        if cmd == "load":
            mode, img_path, secret_path, success, img_name = setup_system()
            img_name = pathlib.PureWindowsPath(img_name).stem
            if success == True:
                if mode == 0:
                    image_data, image_shape[0], image_shape[1] = load_image(img_path)
                    secret_data = load_secret(secret_path)
                    secret_byte = conv_secret(secret_data)
                    image_size = image_shape[0] * image_shape[1]
                    secret_size_ps = len(secret_byte)
                    secret_size_pl = len(secret_data)
                    if secret_size_ps > image_size:
                        print("[Error] Secret text too large")
                elif mode == 1:
                    image_data, image_shape[0], image_shape[1] = load_image(img_path)
                    image_size = image_shape[0] * image_shape[1]
                else:
                    print("[Error] Operating mode is invalid")
        elif cmd == "pl_embed":
            if mode == 0:
                hard_start = time.time()
                image_embed = hw_embed(mode, secret_size_pl, image_shape, image_data, secret_data)
                hard_end = time.time()
                output = Image.fromarray(image_embed)                    
                print(f"Execution time on PL: {hard_end - hard_start} seconds")
                print(f"Save image {img_name}_embed_pl.png to output file")
                output.save(f"./output/{img_name}_embed_pl.png")
                output.save(f"./input/{img_name}_stego.png")
            else:
                print("[Error] Operating mode for command: hw_embed is invalid")
        elif cmd == "pl_extract":
            if mode == 1:
                hard_start = time.time()
                message = hw_extract(mode, image_shape, image_data, image_size)
                hard_end = time.time()                    
                print(f"Execution time on PL: {hard_end - hard_start} seconds")
                str_message = ''.join(map(chr, message))
                print(f"Save message text {img_name}_message_pl.txt to output file")
                message_file = open(f"./output/{img_name}_message_pl.txt", "w")
                message_file.write(str_message)
                message_file.close()
                shutil.copyfile(f"./output/{img_name}_message_pl.txt", f"./input/{img_name}_pl.txt")
            else:
                print("[Error] Operating mode for command: hw_extract is invalid")
        elif cmd == "pl_reset":
            print("Hardware reset...")
            cdma.reset()
            reg.write(1 * 4, 1)
            reg.write(1 * 4, 0)
        elif cmd == "help":
            print("     load      : load data from microSD card")
            print("     pl_embed  : perform embedding with accelerate system")
            print("     pl_extract: perform extracting with accelerate system")
            print("     pl_reset  : soft reset CDMA and system")
            print("     exit      : exit program")
        else:
            print(f"[Error] Command {cmd} is not supported")  
        print()
        cmd = input(">>> ")
    app_end = time.time()
    print(f"Application usage time: {app_end - app_start} seconds")