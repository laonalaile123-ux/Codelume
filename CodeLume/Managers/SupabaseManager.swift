import Foundation
import Supabase
import Auth

struct UserProfile: Codable {
    let id: UUID
    let username: String
    let avatar_url: String?
    let created_at: Date
    let updated_at: Date
}

// 错误类型枚举
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyRegistered
    case networkError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "请输入有效的邮箱地址"
        case .weakPassword:
            return "密码至少6个字符"
        case .emailAlreadyRegistered:
            return "该邮箱已注册"
        case .networkError:
            return "网络连接失败，请检查网络"
        case .unknownError(let message):
            return "注册失败: \(message)"
        }
    }
}

// 注册数据模型
struct RegistrationData {
    var email: String = ""
    var password: String = ""
    var username: String = ""
    var agreedToTerms: Bool = false
}

// MARK: - Supabase 管理类
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    let client: SupabaseClient
    private let supabaseUrl = URL(string: "https://kpvqflkypukhzkzttcwv.supabase.co")!
    private let supabaseKey = "sb_publishable_2osoNibBOvhyMmv6fyfOOw_hFo9fUa4"
    
    
    @Published var currentSession: Session?
    @Published var isLoading = false
    @Published var registrationSuccess = false
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey,
        )
        loadInitialSession()
    }
    
    private func loadInitialSession() {
        Task {
            do {
                let session = try await client.auth.session
                await MainActor.run {
                    self.currentSession = session
                }
            } catch {
                print("无有效会话: \(error)")
            }
        }
    }
    
    // 🎯 核心注册方法
    func signUp(with data: RegistrationData) async throws {
        // 1. 本地验证
//        try validateRegistrationData(data)
        
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }
        
        do {
            // 2. 调用Supabase注册
            let authResponse = try await client.auth.signUp(
                email: data.email,
                password: data.password,
                data: [
                    "username": .string(data.username),
                    "avatar_url": .string(""),
                    "updated_at": .string(Date().ISO8601Format())
                ]
            )
            
            // 3. 根据邮箱验证配置处理结果
#if DEBUG
            // 开发环境：可能关闭了邮箱验证，直接登录
            if let session = authResponse.session {
                await MainActor.run {
                    self.currentSession = session
                    self.registrationSuccess = true
                }
                print("注册成功，已自动登录（开发模式）")
            } else {
                // 生产环境：需要邮箱验证
                await MainActor.run {
                    self.registrationSuccess = true
                }
                print("注册成功，请查收验证邮件")
                // 这里可以触发发送自定义验证邮件的逻辑
                // try await sendCustomConfirmationEmail(to: data.email)
            }
#else
            // 生产环境总是需要验证
            await MainActor.run {
                self.registrationSuccess = true
            }
            print("注册成功，请查收验证邮件")
#endif
            
            // 4. （可选）在public.profiles表创建用户资料
            try await createUserProfile(userId: authResponse.user.id, username: data.username)
            
        } catch let error as AuthError {
            throw error
        } catch {
            // 处理Supabase返回的具体错误
            let message = await mapSupabaseError(error)
            throw AuthError.unknownError(message)
        }
    }
    
    // 本地数据验证
    private func validateRegistrationData(_ data: RegistrationData) throws {
        // 邮箱格式
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: data.email) else {
            throw AuthError.invalidEmail
        }
        
        // 密码强度
        guard data.password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        // 用户名
        guard !data.username.isEmpty && data.username.count >= 2 else {
            throw AuthError.unknownError("用户名至少2个字符")
        }
        
        // 条款同意
        guard data.agreedToTerms else {
            throw AuthError.unknownError("请同意服务条款")
        }
    }
    
    // 错误映射
    private func mapSupabaseError(_ error: Error) async -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("already registered") ||
            errorString.contains("user_exists") {
            return "该邮箱已注册"
        } else if errorString.contains("password") {
            return "密码不符合要求"
        } else if errorString.contains("email") {
            return "邮箱格式无效"
        } else if errorString.contains("network") {
            return "网络连接失败"
        } else {
            return "注册失败，请重试"
        }
    }
    
    // 创建用户资料表记录
    private func createUserProfile(userId: UUID, username: String) async throws {
        // 确保profiles表存在且开启RLS
        let profile = UserProfile(
            id: userId,
            username: username,
            avatar_url: "",
            created_at: Date(),
            updated_at: Date()
        )
        
        do {
            try await client
                .from("profiles")
                .insert(profile)
                .execute()
            print("用户资料创建成功")
        } catch {
            // 这里可以记录日志，但不一定让注册失败
            print("创建用户资料失败（可忽略）: \(error)")
        }
    }
    
    // 发送自定义验证邮件（可选）
    private func sendCustomConfirmationEmail(to email: String) async throws {
        // 使用Supabase Edge Functions或自有后端发送
        print("向 \(email) 发送验证邮件")
    }
    
    // 获取所有动态壁纸
    func getAllWallpapers() async throws -> [WallpaperTable] {
        let response: [WallpaperTable] = try await client
            .from("wallpapers")
            .select()
            .execute()
            .value
        Logger.info("Get \(response.count) wallpapers from Supabase.")
        //    try await getPreviewImageUrl(wallpaperBundle: "000000000")
        return response
    }
    
    func getPreviewImageUrl(wallpaperBundle name: String) -> URL {
        let publicURL = URL(string: "https://kpvqflkypukhzkzttcwv.supabase.co/storage/v1/object/public/wallpapers/\(name).bundle/preview/thumbnail.jpg")
        print("公开URL: \(publicURL)")
        return publicURL!
    }
}
