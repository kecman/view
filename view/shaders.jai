TEXT_SHADER_STR_VERTEX :: #string END_SHADER
#version 330 core
layout (location = 0) in vec4 vertex; // xy is pos, zw are texture coords

out vec2 TextureCoords;

uniform mat4 projection;

void main()
{
    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
    TextureCoords = vertex.zw;
}
END_SHADER




TEXT_SHADER_STR_FRAGMENT :: #string END_SHADER
#version 330 core
in vec2 TextureCoords;
out vec4 color;

uniform sampler2D text;
uniform vec4 text_color;

void main () {
    vec4 sample = vec4(1.0, 1.0, 1.0, texture(text, TextureCoords).r);
    color = text_color * sample;
    // color = vec4(TextureCoords, 0.0, 1.0);
    // color = vec4(texture(text, TextureCoords).rrr, 1.0);
}
END_SHADER


text_shader   : GLuint;
text_vao   : GLuint;
text_vbo   : GLuint;


get_shader_program :: (shader_vertex : string, shader_fragment : string) -> GLuint {
    make_shader_object :: (shader : string, shader_type : GLenum) -> GLuint {
        shader_object := glCreateShader(shader_type);

        //shader_str := temp_c_string(shader);
		length : GLint = xx shader.count;
        glShaderSource(shader_object, 1, *shader.data, *length);

        glCompileShader(shader_object);

        success : GLint;
        glGetShaderiv(shader_object, GL_COMPILE_STATUS, *success);

        if !success then {
            log : [512] u8;
            glGetShaderInfoLog(shader_object, 512, null, log.data);
            print("[Shader] %\n", to_string(log.data));
            exit(1); // Hard-exit for now.
        }

        return shader_object;
    }

    shader_v := make_shader_object(shader_vertex, GL_VERTEX_SHADER);
    shader_f := make_shader_object(shader_fragment, GL_FRAGMENT_SHADER);
    shader_p := glCreateProgram();

    glAttachShader(shader_p, shader_v);
    glAttachShader(shader_p, shader_f);
    glLinkProgram(shader_p);

    success : GLint = 0;
    glGetProgramiv(shader_p, GL_LINK_STATUS, *success);

    if !success then {
        BUFFER_SIZE_LOG :: 512;
        log : [BUFFER_SIZE_LOG] u8;
        glGetProgramInfoLog(shader_p, BUFFER_SIZE_LOG, null, log.data);
        print("[Shader] %\n", to_string(log.data));
        exit(1); // Hard-exit for now.
    } 

    glDeleteShader(shader_v);
    glDeleteShader(shader_f);

    return shader_p;
}


