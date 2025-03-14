#include <hip/hip_runtime.h>
#include <hip/hip_fp16.h>
#include <gtest/gtest.h>
#include <vector>
#include <cmath>
#include "matmul_fp16.0dab83ee_0d1d2d34567c89c1011c.h"

class MatmulFP16Test : public ::testing::Test {
protected:
    void SetUp() override {
        // Initialize HIP
        ASSERT_EQ(hipSuccess, hipInit(0));
        
        // Set dimensions that are multiples of BLOCK_M/N/K (16)
        M = 16;
        N = 16;
        K = 16;
        
        // Allocate host memory
        h_A.resize(M * K);
        h_B.resize(K * N);
        h_C.resize(M * N);
        h_expected.resize(M * N);
        
        // Initialize input matrices with test data
        for (int i = 0; i < M * K; i++) {
            h_A[i] = __float2half(1.f);  // Some pattern for matrix A
        }
        for (int i = 0; i < K * N; i++) {
            h_B[i] = __float2half(1.f);  // Some pattern for matrix B
        }
        
        // Calculate expected results in FP32 for higher precision
        calculateExpectedResult();
        
        // Allocate device memory
        ASSERT_EQ(hipSuccess, hipMalloc(&d_A, M * K * sizeof(__half)));
        ASSERT_EQ(hipSuccess, hipMalloc(&d_B, K * N * sizeof(__half)));
        ASSERT_EQ(hipSuccess, hipMalloc(&d_C, M * N * sizeof(__half)));
        
        // Copy input data to device
        ASSERT_EQ(hipSuccess, hipMemcpy(d_A, h_A.data(), M * K * sizeof(__half), hipMemcpyHostToDevice));
        ASSERT_EQ(hipSuccess, hipMemcpy(d_B, h_B.data(), K * N * sizeof(__half), hipMemcpyHostToDevice));
    }
    
    void TearDown() override {
        hipFree(d_A);
        hipFree(d_B);
        hipFree(d_C);
    }
    
    void calculateExpectedResult() {
        // Calculate reference result in FP32 for better accuracy
        for (int m = 0; m < M; m++) {
            for (int n = 0; n < N; n++) {
                float sum = 0.0f;
                for (int k = 0; k < K; k++) {
                    sum += __half2float(h_A[m * K + k]) * __half2float(h_B[k * N + n]);
                }
                h_expected[m * N + n] = __float2half(sum);
            }
        }
    }
    
    bool compareResults() {
        const float tolerance = 0.01f;  // Adjust based on needed precision
        for (int i = 0; i < M * N; i++) {
            std::cout<<__half2float(h_C[i])<<' '<<__half2float(h_expected[i])<<std::endl;
            float diff = std::abs(__half2float(h_C[i]) - __half2float(h_expected[i]));
            if (diff > tolerance) {
                return false;
            }
        }
        return true;
    }
    
    int M, N, K;
    std::vector<__half> h_A, h_B, h_C, h_expected;
    hipDeviceptr_t d_A, d_B, d_C;
};

TEST_F(MatmulFP16Test, CorrectResult) {
    hipStream_t stream;
    ASSERT_EQ(hipSuccess, hipStreamCreate(&stream));
    
    // Call the matrix multiplication function
    ASSERT_EQ(hipSuccess, matmul_fp16_0dab83ee_0d1d2d34567c89c1011c(
        stream, d_C, d_A, d_B, M, N, K, N, K, N));
    
    // Synchronize and check for errors
    ASSERT_EQ(hipSuccess, hipStreamSynchronize(stream));
    
    // Copy result back to host
    ASSERT_EQ(hipSuccess, hipMemcpy(h_C.data(), d_C, M * N * sizeof(__half), hipMemcpyDeviceToHost));
    
    // Verify results
    EXPECT_TRUE(compareResults());
    
    hipStreamDestroy(stream);
}

// TEST_F(MatmulFP16Test, ZeroDimension) {
//     hipStream_t stream;
//     ASSERT_EQ(hipSuccess, hipStreamCreate(&stream));
    
//     // Test with zero dimensions
//     hipError_t result = matmul_fp16_36f7d82d_0d1d2d34567c89c10d11c(
//         stream, d_C, d_A, d_B, 0, N, K, N, K, N);
    
//     // Should handle zero dimensions gracefully
//     EXPECT_EQ(hipSuccess, result);
    
//     hipStreamDestroy(stream);
// }