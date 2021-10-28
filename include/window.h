#ifndef _WINDOW_H_
#define _WINDOW_H_

#include <glad/glad.h>
#include <GLFW/glfw3.h>

extern unsigned int SCREEN_WIDTH;
extern unsigned int SCREEN_HEIGHT;

void resize_callback(GLFWwindow* window, int width, int height);
void processInput(GLFWwindow *window);
GLFWwindow *window_init();


#endif
