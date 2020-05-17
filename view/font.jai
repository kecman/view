#import "Hash_Table";
#import "freetype255";

FONT_SIZE :: 58;
ASCII_COUNT :: 128;

Char :: struct {
    texture_id : GLuint;
    bearing    : Vector2;
    size       : Vector2;
    advance    : s32;
}

// @Speed We're generating a unique texture id per glyph.
chars : Table(u32, Char);

// 
// Seems Josh uses stb_truetype for his own stuff, giving you an entire texture atlas for free.
// It will make sense to switch to that as opposed to what I'm doing now, which
// is assigning an unique texture id per glyph.
// -abner 1/16/2018
//
init_font :: () {
    // FreeType Init
    ft : *FT_Library;
    if (FT_Init_FreeType(*ft) != 0) {
        print("[Invaders] Could not init FreeType lib.\n");
        exit(1); // Hard-exit for now.
    }

    face : FT_Face; // KarminaBold.otf
    if (FT_New_Face(ft, temp_c_string("data/Inconsolata.otf"), 0, *face)) {
        print("[Invaders] Could not load data/KarminaBold.otf\n");
        exit(1); // Hard-exit for now.
    }

    FT_Set_Pixel_Sizes(face, 0, FONT_SIZE);

    using gl;
    
    // We're assuming OpenGL has been initialized.
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    for 0..ASCII_COUNT-1 {
        if FT_Load_Char(face, xx it, FT_LOAD_RENDER) {
            print("[Invaders] Failed to load ascii char %\n", it);
            continue;
        }

        texture : GLuint;

        // Generate texture object for glyph.
        {
            glGenTextures(1, *texture);
            glBindTexture(GL_TEXTURE_2D, texture);
            glTexImage2D(GL_TEXTURE_2D, 
                         0, GL_RED, 
                         xx face.glyph.bitmap.width,
                         xx face.glyph.bitmap.rows,
                         0, GL_RED,
                         GL_UNSIGNED_BYTE,
                         face.glyph.bitmap.buffer);
        }

        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        char : Char;
     
        char.texture_id = texture;
        char.bearing = make_vector2(xx face.glyph.bitmap_left, xx face.glyph.bitmap_top);
        char.size = make_vector2(xx face.glyph.bitmap.width, xx face.glyph.bitmap.rows);
        char.advance = xx face.glyph.advance.x;

        table_add(*chars, xx it, char);
    }

    glBindTexture(GL_TEXTURE_2D, 0);

    FT_Done_Face(face);
    FT_Done_FreeType(ft);
}
