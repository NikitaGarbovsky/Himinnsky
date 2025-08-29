package shaderLoader

import "vendor:OpenGL"
import "vendor:glfw"
import "core:strings"
import "core:mem"
import "core:os"
import "core:fmt"

// Creates a program from two passed in shader paths. 
// Once complete, returns the program ID to use in the OpenGL pipeline.
CreateProgramFromShader :: proc(_vertexShaderPath: string, _fragmentShaderPath: string) -> (u32)
{
    // 2x Call createShader and pass the shader type (gl.enum) and the shader path 
    vertexShader : u32 = createShader(OpenGL.VERTEX_SHADER, _vertexShaderPath)
    fragmentShader : u32 = createShader(OpenGL.FRAGMENT_SHADER, _fragmentShaderPath)

    // Creates a new shader program handle 
    program : u32 = OpenGL.CreateProgram()

    // Attach the shaders
    OpenGL.AttachShader(program, vertexShader)
    OpenGL.AttachShader(program, fragmentShader)

    // Link the program.
    OpenGL.LinkProgram(program)

    linkResult : i32
    OpenGL.GetProgramiv(program, OpenGL.LINK_STATUS, &linkResult)

    if linkResult == 0 // false, link failed
    {
        failedProgramShaderStrings := [?]string {_vertexShaderPath, _fragmentShaderPath}

        failedProgramName := strings.concatenate(failedProgramShaderStrings[:])
        defer delete(failedProgramName) // deferes the freeing up of the string memory until after scope exit.

        printErrorDetails(false, program, failedProgramName)
        return 0
    }   

    return program
}

// Creates the shader for use in the OpenGL pipeline, returns its ID.
createShader :: proc(_shaderType: int, _shaderFilePath: string) -> (u32)
{
    // Read the shader files and save the source code as strings
    sShader : string = readShaderFile(_shaderFilePath)

    // Create the shader ID and create pointers for source code string and length
    shaderID : u32 = OpenGL.CreateShader(u32(_shaderType))

    cStyleString : cstring = strings.clone_to_cstring(sShader)
    length := len(cStyleString)

    lenArr := []i32{ i32(length)}

    OpenGL.ShaderSource(shaderID, 1, &cStyleString, &lenArr[0])
    OpenGL.CompileShader(shaderID)

    compileResult : i32
    OpenGL.GetShaderiv(shaderID, OpenGL.COMPILE_STATUS, &compileResult)

    if compileResult == 0 // false, link failed
    {
        printErrorDetails(true, shaderID, _shaderFilePath)
        return 0
    }   

    return shaderID
}

// Opens a shader file and returns its contents.  
readShaderFile :: proc(_fileName : string) -> (string)
{
    // 1. Open and read contents of entire file
    shaderData, linkResult := os.read_entire_file_from_filename(_fileName)

    // 2. Check if that didn't work
    if !linkResult 
    {
        fmt.println("Cannot read shader file: %v", _fileName)
        return ""
    }
    // 3. Return file data
    return string(shaderData)
}

// Prints the logged error details to console for ease of debugging.
printErrorDetails :: proc(_isShader: bool, _Id: u32, _name: string)
{
    infoLogLength : i32 // The length of the error log
    consoleErrorType : string // Assigned depending on type of error

    // First grab the log info length
    if _isShader
    {
        OpenGL.GetShaderiv(_Id, OpenGL.INFO_LOG_LENGTH, &infoLogLength)
    }
    else
    {
        OpenGL.GetProgramiv(_Id, OpenGL.INFO_LOG_LENGTH, &infoLogLength)
    }

    // Create a dynamic array of pointers of type u8 with the length of the log
    log : [^]u8 = make([^]u8, infoLogLength)
    defer free(log) // free it when exiting scope

    // Get the actual log info, fill log 
    if _isShader
    {
        OpenGL.GetShaderInfoLog(_Id, infoLogLength, nil, &log[0])
        consoleErrorType = "Shader" // Assign type of error
    }
    else
    {
        OpenGL.GetProgramInfoLog(_Id, infoLogLength, nil, &log[0])
        consoleErrorType = "Program" // Assign type of error
    }

    // Create new string with the logged data
    errorLoggedInfo := string(log[:infoLogLength])

    // Print the error type with the logged error info
    fmt.println(consoleErrorType, "Error: ", errorLoggedInfo)
}