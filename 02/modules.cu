#include "util.h"
#include "modules.h"

__global__ void relu(const float* input, float* output, int height, int width, int channels) {
    // coordinates of the first pixel to process
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    int z = blockIdx.z * blockDim.z + threadIdx.z;
    // number of processed pixels by step
    int nx = blockDim.x * gridDim.x;
    int ny = blockDim.y * gridDim.y;
    int nz = blockDim.z * gridDim.z;
    // global thread id and count
    int t = z * nx * ny + y * nx + x;
    int num_threads = nx * ny * nz;

    // loop replaces if statement, in most cases calculated once
    for (int out_z = z; out_z < channels; out_z += nz) {
        for (int out_y = y; out_y < height; out_y += ny) {
            for (int out_x = x; out_x < width; out_x += nx) {
                int linear_idx = out_z * height * width + out_y * width + out_x;
                if (input[linear_idx] > 0) {
                    output[linear_idx] = input[linear_idx];
                } else {
                    output[linear_idx] = 0;
                }
            }
        }
    }
}

void ReLU::forward(const float* input_device, float* output_device, int height, int width, int channels) const {
    dim3 grid_dim((width + BLOCK_SIZE - 1) / BLOCK_SIZE, (height + BLOCK_SIZE - 1) / BLOCK_SIZE);
    dim3 block_dim(BLOCK_SIZE, BLOCK_SIZE);
    relu<<<grid_dim, block_dim>>>(input_device, output_device, height, width, channels);
}

__global__ void sigmoid(const float* input, float* output, int height, int width, int channels) {
    // coordinates of the first pixel to process
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    int z = blockIdx.z * blockDim.z + threadIdx.z;
    // number of processed pixels by step
    int nx = blockDim.x * gridDim.x;
    int ny = blockDim.y * gridDim.y;
    int nz = blockDim.z * gridDim.z;
    // global thread id and count
    int t = z * nx * ny + y * nx + x;
    int num_threads = nx * ny * nz;

    // loop replaces if statement, in most cases calculated once
    for (int out_z = z; out_z < channels; out_z += nz) {
        for (int out_y = y; out_y < height; out_y += ny) {
            for (int out_x = x; out_x < width; out_x += nx) {
                int linear_idx = out_z * height * width + out_y * width + out_x;
                output[linear_idx] = 1 / (1 + exp(-input[linear_idx]));
            }
        }
    }
}

void Sigmoid::forward(const float* input_device, float* output_device, int height, int width, int channels) const {
    dim3 grid_dim((width + BLOCK_SIZE - 1) / BLOCK_SIZE, (height + BLOCK_SIZE - 1) / BLOCK_SIZE);
    dim3 block_dim(BLOCK_SIZE, BLOCK_SIZE);
    sigmoid<<<grid_dim, block_dim>>>(input_device, output_device, height, width, channels);
}

__global__ void maxpool(const float* input, float* output, int height, int width, int channels) {
    // coordinates of the first pixel to process
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    int z = blockIdx.z * blockDim.z + threadIdx.z;
    // number of processed pixels by step
    int nx = blockDim.x * gridDim.x;
    int ny = blockDim.y * gridDim.y;
    int nz = blockDim.z * gridDim.z;
    // global thread id and count
    int t = z * nx * ny + y * nx + x;
    int num_threads = nx * ny * nz;

    int h_2 = (height + 1) / 2;
    int w_2 = (width + 1) / 2;

    // loop replaces if statement, in most cases calculated once
    for (int out_z = z; out_z < channels; out_z += nz) {
        for (int out_y = y; out_y < h_2; out_y += ny) {
            for (int out_x = x; out_x < w_2; out_x += nx) {
                int c00 = out_z * height * width + (out_y * 2) * width + (out_x * 2);
                int c01 = c00 + 1;
                int c10 = c00 + width;
                int c11 = c10 + 1;
                if (out_x * 2 + 1 >= width) {
                    c01 = c00;
                    c11 = c10;
                }
                if (out_y * 2 + 1 >= height) {
                    c10 = c00;
                    c11 = c01;
                }
                int linear_idx = out_z * h_2 * w_2 + out_y * w_2 + out_x;
                output[linear_idx] = max(max(max(input[c00], input[c01]), input[c10]), input[c11]);
            }
        }
    }
}

void MaxPool2d::forward(const float* input_device, float* output_device, int height, int width, int channels) const {
    dim3 grid_dim((width + BLOCK_SIZE - 1) / BLOCK_SIZE, (height + BLOCK_SIZE - 1) / BLOCK_SIZE);
    dim3 block_dim(BLOCK_SIZE, BLOCK_SIZE);
    maxpool<<<grid_dim, block_dim>>>(input_device, output_device, height, width, channels);
}
